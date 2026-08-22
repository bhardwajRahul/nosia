require "test_helper"

class AuthenticationLifecycleTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "life@example.com", password: "testpassword123")
    @account = Account.create!(name: "Life Account", owner: @user)
  end

  test "login with a wrong password creates no session" do
    assert_no_difference -> { Session.count } do
      post login_url, params: { email: @user.email, password: "wrong-password" }

      assert_response :unauthorized
    end
  end

  test "logout destroys the session" do
    post login_url, params: { email: @user.email, password: "testpassword123" }
    assert_equal 1, Session.count

    delete logout_url

    assert_redirected_to root_path
    assert_empty Session.all
  end

  # First-run setup is the one unauthenticated write in the app: once any
  # account exists it must be inert, or anyone could claim a fresh install's
  # owner account by re-triggering setup.
  test "first run setup is blocked once an account exists" do
    assert_no_difference -> { User.count } do
      get first_run_url
      assert_redirected_to root_path

      post first_run_url, params: { user: { email: "hijack@example.com", password: "x" * 12 } }
      assert_redirected_to root_path
    end
  end

  test "first run setup is available before any account exists" do
    Account.destroy_all
    User.destroy_all

    get first_run_url
    assert_response :success
  end
end
