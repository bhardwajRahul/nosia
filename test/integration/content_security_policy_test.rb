require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  # Baseline containment that cannot break existing rendering: the page must
  # not be framable by third parties (clickjacking), and plugin/base-uri
  # vectors are closed. A full script/style policy needs the inline scripts in
  # dashboards/mcp forms ported to Stimulus first — tracked separately.
  test "baseline CSP headers are emitted" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "expected a Content-Security-Policy header"
    assert_includes csp, "frame-ancestors 'self'"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "base-uri 'self'"
  end
end
