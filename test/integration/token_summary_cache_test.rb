require "test_helper"

class TokenSummaryCacheTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "tsc@example.com", password: "testpassword123")
    @account = Account.create!(name: "TSC Account", owner: @user)
    @account.account_users.grant_to(@user)
    post login_url, params: { email: @user.email, password: "testpassword123" }

    # Fragments need a real store to be observable: the default test store is
    # NullStore, and the controller captured it at boot — so swap both.
    @previous_cache = Rails.cache
    @previous_perform_caching = ActionController::Base.perform_caching
    @previous_controller_store = ActionController::Base.cache_store
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.cache_store = Rails.cache
    ActionController::Base.perform_caching = true
  end

  def teardown
    Rails.cache = @previous_cache
    ActionController::Base.cache_store = @previous_controller_store
    ActionController::Base.perform_caching = @previous_perform_caching
  end

  # The cache key was [account, "token-usage-summary"]; update_counters bumps
  # the token columns without touching the account row, so updated_at stayed
  # put and the fragment served forever-stale totals.
  test "summary reflects usage recorded after the fragment was cached" do
    create_usage(input_tokens: 1234, output_tokens: 11)

    get token_usage_url
    assert_response :success
    assert_includes response.body, "1,234", "first render must show the initial total"

    create_usage(input_tokens: 2211, output_tokens: 22)

    get token_usage_url
    assert_response :success
    assert_includes response.body, "3,445", "fragment must be invalidated when counters move"
    assert_not_includes response.body, "1,234"
  end

  private

  def create_usage(input_tokens:, output_tokens:)
    TokenUsage.create!(
      account: @account,
      kind: :completion,
      model_id: "test-model",
      input_tokens: input_tokens,
      output_tokens: output_tokens
    )
  end
end
