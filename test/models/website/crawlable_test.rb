require "test_helper"

class Website::CrawlableTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "cw@example.com", password: "testpassword123")
    @account = Account.create!(name: "CW Account", owner: @user)
    ActsAsTenant.current_tenant = @account
    @website = @account.websites.create!(url: "https://example.com/page")
  end

  def teardown
    ActsAsTenant.current_tenant = nil
    unstub_url_resolver
  end

  def stub_connection(status:, body: "")
    response = Struct.new(:status, :body).new(status, body)
    response.define_singleton_method(:success?) { status.between?(200, 299) }
    connection = Object.new
    connection.define_singleton_method(:get) { |*_args| response }
    @website.define_singleton_method(:faraday_connection) { connection }
  end

  test "crawl_url! refuses hosts that resolve to private networks" do
    stub_url_resolver([ "127.0.0.1" ])
    # No faraday stub: the guard must trip before any network access happens.

    assert_nothing_raised { @website.crawl_url! }

    assert @website.reload.failed?
  end

  test "crawl_url! refuses non-http url schemes" do
    @website.update!(url: "file:///etc/passwd")

    assert_nothing_raised { @website.crawl_url! }

    assert @website.reload.failed?
  end

  test "crawl_url! still crawls public hosts" do
    stub_url_resolver([ "93.184.216.34" ])
    stub_connection(status: 200, body: "<h1>Title</h1>")

    @website.crawl_url!

    assert @website.reload.indexed?
  end
end
