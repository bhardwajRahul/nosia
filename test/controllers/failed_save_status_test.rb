require "test_helper"

class FailedSaveStatusTest < ActionDispatch::IntegrationTest
  # Turbo Drive treats a 200 as success: failed saves must render their form
  # (or show page) with 422 or the client never learns the write failed.

  def setup
    @user = User.create!(email: "fs@example.com", password: "testpassword123")
    @account = Account.create!(name: "FS Account", owner: @user)
    @account.account_users.grant_to(@user)
    ActsAsTenant.current_tenant = @account
    post login_url, params: { email: @user.email, password: "testpassword123" }
  end

  def teardown
    ActsAsTenant.current_tenant = nil
  end

  test "agent skill create failure renders 422" do
    post agent_skills_path, params: { agent_skill: { name: "", execution_mode: :llm, trigger_mode: :explicit, skill_content: "x" } }

    assert_response :unprocessable_entity
  end

  test "agent skill update failure renders 422" do
    skill = @account.agent_skills.create!(name: "keep", execution_mode: :llm, trigger_mode: :explicit, skill_content: "x")

    patch agent_skill_path(skill), params: { agent_skill: { name: "" } }

    assert_response :unprocessable_entity
  end

  test "system prompt update failure renders 422" do
    prompt = @account.create_default_system_prompt!(user: nil)

    patch system_prompt_path(prompt), params: { prompt: { content: "" } }

    assert_response :unprocessable_entity
  end

  test "account system prompt update failure renders 422" do
    patch account_system_prompt_path(@account), params: { prompt: { content: "" } }

    assert_response :unprocessable_entity
  end
end
