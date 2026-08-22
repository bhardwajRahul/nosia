require "test_helper"

class McpServerTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "ms@example.com", password: "testpassword123")
    @account = Account.create!(name: "MS Account", owner: @user)
    ActsAsTenant.current_tenant = @account
  end

  def teardown
    ActsAsTenant.current_tenant = nil
    unstub_url_resolver
    ENV["MCP_STDIO_ENABLED"] = @previous_stdio_env
  end

  test "stdio transport is rejected unless enabled for the deployment" do
    ENV.delete("MCP_STDIO_ENABLED")

    server = @account.mcp_servers.new(
      name: "shell", transport_type: "stdio", command: "curl", args: [ "https://evil.example" ]
    )

    assert_not server.valid?
    assert_not_empty server.errors[:transport_type]
  end

  test "stdio transport is allowed when MCP_STDIO_ENABLED is set" do
    @previous_stdio_env = nil
    ENV["MCP_STDIO_ENABLED"] = "true"

    server = @account.mcp_servers.new(name: "local-tool", transport_type: "stdio", command: "npx")

    assert server.valid?
  end

  test "streamable endpoints on private hosts are rejected" do
    stub_url_resolver([ "127.0.0.1" ])

    server = @account.mcp_servers.new(
      name: "internal", transport_type: "streamable", endpoint: "http://127.0.0.1:9222/mcp"
    )

    assert_not server.valid?
    assert_not_empty server.errors[:endpoint]
  end

  test "sse endpoints on public hosts are accepted" do
    stub_url_resolver([ "93.184.216.34" ])

    server = @account.mcp_servers.new(
      name: "public", transport_type: "sse", endpoint: "https://mcp.example.com/sse"
    )

    assert server.valid?
  end

  test "scheme-less endpoints are validated as https" do
    stub_url_resolver([ "10.1.2.3" ])

    server = @account.mcp_servers.new(
      name: "bare", transport_type: "streamable", endpoint: "10.1.2.3:9222/mcp"
    )

    assert_not server.valid?
    assert_not_empty server.errors[:endpoint]
  end
end
