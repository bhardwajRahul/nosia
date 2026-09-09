require "test_helper"

# The inline scripts these pages used to carry were ported to Stimulus
# controllers; these renders guard the ERB against regressions and keep the
# CSP-relevant markup (no raw <script>) honest.
class PortedScriptPagesRenderTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "port@example.com", password: "testpassword123")
    @account = Account.create!(name: "Port Account", owner: @user)
    @account.account_users.grant_to(@user)
    post login_url, params: { email: @user.email, password: "testpassword123" }
  end

  test "dashboard renders without any unnonced script tag" do
    get user_root_url

    assert_response :success
    assert_select "script" do |scripts|
      scripts.each do |script|
        assert_not script["nonce"].nil?, "every script must carry a nonce"
      end
    end
  end

  test "mcp server form renders with controller wiring intact" do
    get new_mcp_server_url

    assert_response :success
    assert_select '[data-controller~="mcp-form"]'
    assert_select '[data-mcp-form-target="httpFields"]'
    assert_select '[data-mcp-form-target="stdioFields"]'
    assert_select "script", count: 0, text: /turbo:load/
  end

  test "sources index renders the auto-submit toolbar" do
    get sources_path

    assert_response :success
    assert_select 'form[data-controller~="auto-submit"]'
  end
end
