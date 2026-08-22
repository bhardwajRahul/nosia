require "test_helper"

class UrlGuardTest < ActiveSupport::TestCase
  def teardown
    unstub_url_resolver
  end

  test "verify! returns the parsed uri for publicly routable hosts" do
    stub_url_resolver([ "93.184.216.34" ])

    uri = UrlGuard.verify!("https://example.com/page")

    assert_equal URI("https://example.com/page"), uri
  end

  test "allows both http and https schemes" do
    stub_url_resolver([ "93.184.216.34" ])

    assert UrlGuard.safe?("http://example.com")
    assert UrlGuard.safe?("https://example.com")
  end

  test "blocks non-http schemes" do
    refute UrlGuard.safe?("file:///etc/passwd")
    refute UrlGuard.safe?("ftp://example.com/file")
    refute UrlGuard.safe?("gopher://example.com")
  end

  test "blocks hosts resolving to loopback, private, or link-local ranges" do
    stub_url_resolver([ "93.184.216.34" ])
    blocked_ips = [
      "0.0.0.0",
      "127.0.0.1",
      "10.0.0.5",
      "100.64.1.1",
      "169.254.169.254", # cloud metadata endpoint
      "172.16.0.9",
      "192.168.1.1",
      "::1",
      "fd00::1",
      "fe80::1"
    ]

    blocked_ips.each do |ip|
      stub_url_resolver([ ip ])
      refute UrlGuard.safe?("https://internal.example"), "#{ip} must be blocked"
    end
  end

  test "blocks ipv4-mapped ipv6 addresses" do
    stub_url_resolver([ "::ffff:127.0.0.1" ])

    refute UrlGuard.safe?("https://sneaky.example")
  end

  test "blocks hosts that do not resolve" do
    stub_url_resolver([])

    refute UrlGuard.safe?("https://void.example")
  end

  test "blocks any address when resolution includes a private one" do
    stub_url_resolver([ "93.184.216.34", "10.0.0.5" ])

    refute UrlGuard.safe?("https://mixed.example")
  end

  test "resolves localhost to loopback without a stub" do
    refute UrlGuard.safe?("http://localhost:3000/admin")
    refute UrlGuard.safe?("http://127.0.0.1/x")
  end

  test "safe? never raises on malformed urls" do
    refute UrlGuard.safe?(nil)
    refute UrlGuard.safe?("")
    refute UrlGuard.safe?("not a url at all :::")
  end
end
