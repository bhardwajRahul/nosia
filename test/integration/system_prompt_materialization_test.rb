require "test_helper"

class SystemPromptMaterializationTest < ActionDispatch::IntegrationTest
  # Account#system_prompt already falls back to the shipped default when no
  # Prompt row exists, so GETs have no reason to write. Read actions must stay
  # read-only; only an explicit update may materialize the row.
  def setup
    @user = User.create!(email: "spm@example.com", password: "testpassword123")
    @account = Account.create!(name: "SPM Account", owner: @user)
    @account.account_users.grant_to(@user)
    post login_url, params: { email: @user.email, password: "testpassword123" }
  end

  test "index lists prompts without creating any" do
    assert_no_difference -> { Prompt.count } do
      get system_prompts_path
    end

    assert_response :success
  end

  test "account prompt show does not create the record" do
    assert_no_difference -> { Prompt.count } do
      get account_system_prompt_path(@account)
    end

    assert_response :success
  end

  test "account prompt edit does not create the record" do
    assert_no_difference -> { Prompt.count } do
      get edit_account_system_prompt_path(@account)
    end

    assert_response :success
  end

  test "updating a missing account prompt creates and saves it" do
    assert_difference -> { Prompt.count }, 1 do
      patch account_system_prompt_path(@account), params: { prompt: { content: "custom rules" } }
    end

    assert_redirected_to account_system_prompt_path(@account)
    assert_equal "custom rules", @account.reload.system_prompt
  end
end
