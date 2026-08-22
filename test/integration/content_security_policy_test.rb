require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "csp@example.com", password: "testpassword123")
    @account = Account.create!(name: "CSP Account", owner: @user)
    @account.account_users.grant_to(@user)
    post login_url, params: { email: @user.email, password: "testpassword123" }
  end

  test "strict script policy with per-session nonce is emitted" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "expected a Content-Security-Policy header"
    assert_includes csp, "frame-ancestors 'self'"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "base-uri 'self'"

    script = csp[/script-src [^;]+/]
    assert script, "expected a script-src directive"
    assert_includes script, "'self'"
    assert_includes script, "'nonce-"
    assert_not_includes script, "unsafe-inline", "scripts must not fall back to unsafe-inline"
  end

  test "authenticated layout scripts carry a matching nonce" do
    get user_root_url

    assert_response :success
    nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
    assert nonce.present?

    assert_select "script[nonce=?]", CGI.escapeHTML(nonce)
  end
end
