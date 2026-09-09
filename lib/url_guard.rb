# Guards outbound fetches against SSRF: only http(s) to publicly routable
# hosts. Used by the website crawler and MCP server endpoint validation.
#
# Note the TOCTOU window between this check and the actual request: a hostile
# DNS server can still rebind a hostname between resolution and fetch. Closing
# that requires pinning the resolved IP onto the connection itself.
class UrlGuard
  class Blocked < StandardError; end

  ALLOWED_SCHEMES = %w[http https].freeze

  # Loopback, RFC1918 + CGNAT + link-local (cloud metadata), and IPv6
  # equivalents. 0.0.0.0/8 covers "this network" and unspecified targets.
  BLOCKED_RANGES = [
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("100.64.0.0/10"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  class << self
    # Returns the parsed URI when safe; raises UrlGuard::Blocked otherwise.
    def verify!(url)
      uri = parse(url)
      raise Blocked, "scheme not allowed" unless ALLOWED_SCHEMES.include?(uri.scheme&.downcase)
      raise Blocked, "host missing" if uri.host.to_s.strip.empty?

      addresses = resolve(uri.host)
      raise Blocked, "host does not resolve" if addresses.empty?
      raise Blocked, "host resolves to a private address" if addresses.any? { |ip| blocked_ip?(ip) }

      uri
    end

    def safe?(url)
      verify!(url)
      true
    rescue Blocked, URI::Error, SocketError, TypeError, ArgumentError
      false
    end

    # Resolves a hostname to a list of IPAddr. Numeric hosts resolve locally,
    # no DNS involved.
    def resolve(host)
      Addrinfo.getaddrinfo(host, nil).filter_map { |addr| IPAddr.new(addr.ip_address) }
    rescue SocketError
      []
    end

    private

    def parse(url)
      URI.parse(url.to_s.strip)
    end

    def blocked_ip?(address)
      address = address.native if address.ipv6? && address.ipv4_mapped?
      BLOCKED_RANGES.any? { |range| range.include?(address) }
    end
  end
end
