require "test_helper"

class Sources::QnasControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "qna@example.com", password: "testpassword123")
    @account = Account.create!(name: "QnA Account", owner: @user)
    @account.account_users.grant_to(@user)
    ActsAsTenant.current_tenant = @account
    post login_url, params: { email: @user.email, password: "testpassword123" }

    @stranger = User.create!(email: "qna-stranger@example.com", password: "testpassword123")
    @foreign_account = Account.create!(name: "Foreign Account", owner: @stranger)
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  test "create cannot file a qna under another user's account" do
    post sources_qnas_url, params: {
      qna: { question: "Poison?", answer: "Hostile answer", account_id: @foreign_account.id }
    }

    assert_response :not_found
    assert_empty Qna.where(question: "Poison?")
  end
end
