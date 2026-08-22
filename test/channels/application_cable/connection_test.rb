require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    def setup
      @user = User.create!(email: "cable@example.com", password: "testpassword123")
      @session = @user.sessions.create!(user_agent: "TestAgent", ip_address: "127.0.0.1")
    end

    # Turbo stream tokens are bearer strings: possession alone must not grant a
    # socket. Every websocket is identified by the live signed session cookie,
    # so anonymous clients are rejected at handshake instead of silently
    # receiving broadcasts they can sniff tokens for.
    test "connects with a valid session cookie" do
      cookies.signed[:session_id] = @session.id

      connect

      assert_equal @session.id, connection.current_session.id
    end

    test "rejects connections without a session cookie" do
      assert_reject_connection { connect }
    end

    test "rejects connections whose session no longer exists" do
      cookies.signed[:session_id] = Session.maximum(:id).to_i + 1000

      assert_reject_connection { connect }
    end
  end
end
