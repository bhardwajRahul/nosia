require "test_helper"

class Sources::TextsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "st@example.com", password: "testpassword123")
    @account = Account.create!(name: "ST Account", owner: @user)
    @account.account_users.grant_to(@user)
    ActsAsTenant.current_tenant = @account
    post login_url, params: { email: @user.email, password: "testpassword123" }

    @stranger = User.create!(email: "st-stranger@example.com", password: "testpassword123")
    @foreign_account = Account.create!(name: "Foreign Account", owner: @stranger)
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  # new builds a Text with nil data; Commonmarker.to_html rejects the
  # US-ASCII empty string that nil.to_s yields unless we force UTF-8.
  test "new renders without an encoding error for a blank text" do
    get new_sources_text_url

    assert_response :success
  end

  test "create cannot file a text under another user's account" do
    post sources_texts_url, params: {
      text: { data: "hostile corpus", account_id: @foreign_account.id }
    }

    assert_response :not_found
    assert_empty Text.where(data: "hostile corpus")
  end
end
