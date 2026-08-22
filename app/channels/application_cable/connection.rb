module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_session

    def connect
      self.current_session = find_verified_session
    end

    private

    # Turbo stream tokens are bearer strings; without an authenticated socket,
    # possession of a token alone would grant a permanent read on everything
    # broadcast there. Requiring the live signed session cookie ties every
    # subscription to a real login.
    def find_verified_session
      if (session_id = cookies.signed[:session_id])
        Session.find_by(id: session_id)
      end || reject_unauthorized_connection
    end
  end
end
