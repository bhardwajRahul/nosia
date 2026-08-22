require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "apit@example.com", password: "testpassword123")
    @account = Account.create!(name: "APIT Account", owner: @user)
    @account.account_users.grant_to(@user)
    post login_url, params: { email: @user.email, password: "testpassword123" }
  end

  # Show-once semantics: the plaintext appears in the create response only,
  # never on later page loads, and nothing re-renders stored tokens.
  test "create reveals the token once and never again" do
    assert_difference -> { ApiToken.count }, 1 do
      post api_tokens_path, params: { api_token: { account_id: @account.id, name: "deploy key" } }
    end

    assert_redirected_to api_tokens_path
    follow_redirect!

    plain = response.body[%r{value="([A-Za-z0-9]{24})"}, 1]
    assert plain, "the plaintext token must be shown once after creation"
    created = ApiToken.find_by!(name: "deploy key")
    assert_equal ApiToken.digest(plain), created.token_digest

    get api_tokens_path
    assert_not_includes response.body, plain, "the plaintext must not be shown again"
    assert_not_includes response.body, created.token_digest, "digests are internal"
  end
end
