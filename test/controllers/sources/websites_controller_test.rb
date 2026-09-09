require "test_helper"

class Sources::WebsitesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "webc@example.com", password: "testpassword123")
    @account = Account.create!(name: "Web Account", owner: @user)
    @account.account_users.grant_to(@user)
    ActsAsTenant.current_tenant = @account
    post login_url, params: { email: @user.email, password: "testpassword123" }

    @stranger = User.create!(email: "webc-stranger@example.com", password: "testpassword123")
    @foreign_account = Account.create!(name: "Foreign Account", owner: @stranger)
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  test "create cannot file a website under another user's account" do
    post sources_websites_url, params: {
      website: { url: "https://poison.example/page", data: "hostile", account_id: @foreign_account.id }
    }

    assert_response :not_found
    assert_empty Website.where(url: "https://poison.example/page")
  end
end
