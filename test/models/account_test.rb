require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "at@example.com", password: "testpassword123")
    @account = Account.create!(name: "AT Account", owner: @user)
    ActsAsTenant.current_tenant = @account
  end

  test "recount! repairs drifted account counters" do
    TokenUsage.create!(account: @account, kind: :embedding, input_tokens: 70, output_tokens: 0)
    @account.update!(input_tokens_count: 0, output_tokens_count: 0) # simulate drift
    @account.recount!
    assert_equal 70, @account.reload.input_tokens_count
  end

  test "green_it_summary aggregates per-model and embedding energy" do
    TokenUsage.create!(account: @account, kind: :completion, model_id: "model-a", input_tokens: 1000, output_tokens: 0)
    TokenUsage.create!(account: @account, kind: :completion, model_id: "model-b", input_tokens: 500, output_tokens: 0)
    TokenUsage.create!(account: @account, kind: :embedding, model_id: nil, input_tokens: 2000, output_tokens: 0)

    summary = @account.green_it_summary

    assert_equal [ "model-a", "model-b" ], summary[:models].map { |e| e[:model_id] }
    assert_equal 1000, summary[:models].first[:tokens]

    expected_kwh =
      GreenIt.energy_kwh(tokens: 1000, model_id: "model-a", kind: :completion)[:kwh] +
      GreenIt.energy_kwh(tokens: 500, model_id: "model-b", kind: :completion)[:kwh] +
      GreenIt.energy_kwh(tokens: 2000, model_id: nil, kind: :embedding)[:kwh]

    assert_in_delta expected_kwh, summary[:kwh], 1e-12
    assert_in_delta GreenIt.co2e_g(kwh: expected_kwh), summary[:co2e_g], 1e-9
  end
end
