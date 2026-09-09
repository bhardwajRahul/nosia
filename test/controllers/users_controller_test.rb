require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  # Registration is a spam magnet: unauthenticated writes get a per-IP ceiling
  # like login already has. The limiter counts attempts even while
  # registrations are closed.
  test "registration attempts are rate limited" do
    self.remote_addr = "10.9.9.9"
    ENV["REGISTRATIONS_ALLOWED"] = nil

    5.times do |i|
      post users_path, params: { user: { email: "spam#{i}@example.com", password: "x" * 12 } }
      assert_equal "Registrations are closed.", flash[:alert]
    end

    post users_path, params: { user: { email: "spam6@example.com", password: "x" * 12 } }
    assert_redirected_to root_path
    assert_equal "Try again later.", flash[:alert]
  ensure
    ENV["REGISTRATIONS_ALLOWED"] = @previous_registrations
  end

  def setup
    @previous_registrations = ENV["REGISTRATIONS_ALLOWED"]
    ENV["REGISTRATIONS_ALLOWED"] = nil
  end

  def teardown
    ENV["REGISTRATIONS_ALLOWED"] = @previous_registrations
  end
end
