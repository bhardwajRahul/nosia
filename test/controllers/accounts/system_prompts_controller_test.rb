require "test_helper"

module Accounts
  class SystemPromptsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = User.create!(email: "asp@example.com", password: "testpassword123")
      @account = Account.create!(name: "ASP Account", owner: @user)
      @account.account_users.grant_to(@user)
      post login_url, params: { email: @user.email, password: "testpassword123" }

      @stranger = User.create!(email: "asp-stranger@example.com", password: "testpassword123")
      @foreign_account = Account.create!(name: "Foreign Account", owner: @stranger)
    end

    test "update cannot move the account system prompt to another user's account" do
      patch account_system_prompt_url(@account), params: {
        prompt: { content: "hijacked", account_id: @foreign_account.id }
      }

      assert_empty Prompt.where(account: @foreign_account, content: "hijacked")
      assert_equal @account.id, @account.prompts.where(name: "system_prompt").pick(:account_id)
    end
  end
end
