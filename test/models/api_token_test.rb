require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "at@example.com", password: "testpassword123")
    @account = Account.create!(name: "AT Account", owner: @user)
    ActsAsTenant.current_tenant = @account
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  # Plaintext tokens in the database mean one leaked dump replays against the
  # API forever. Only a digest may be stored.
  test "the plaintext token is never persisted" do
    token = ApiToken.create!(account: @account, user: @user, name: "ci")
    plain = token.plain_token

    assert plain.present?, "plain_token must be readable once after creation"
    reloaded = ApiToken.find(token.id)
    assert_not_equal plain, reloaded.token_digest
    assert_equal ApiToken.digest(plain), reloaded.token_digest
    assert_not reloaded.respond_to?(:token), "no plaintext column may exist"
  end

  test "authenticate_token round-trips the plaintext and rejects junk" do
    token = ApiToken.create!(account: @account, user: @user, name: "ci")

    assert_equal token, ApiToken.authenticate_token(token.plain_token)
    assert_nil ApiToken.authenticate_token("garbage")
    assert_nil ApiToken.authenticate_token(nil)
  end

  test "digests are unique across tokens" do
    first = ApiToken.create!(account: @account, user: @user, name: "a")
    second = ApiToken.create!(account: @account, user: @user, name: "b")

    assert_not_equal first.token_digest, second.token_digest
  end
end
