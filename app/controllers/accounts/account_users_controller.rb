# frozen_string_literal: true

module Accounts
  class AccountUsersController < ApplicationController
    before_action :set_account
    before_action :set_user, only: %i[create]
    before_action :set_account_user, only: %i[destroy]
    before_action :require_owner

    def index
      @account_users = @account.account_users.includes(:user)
      @account_user = @account.account_users.new
    end

    def create
      @account_user = @account.account_users.new(user: @user)

      if @account_user.save
        redirect_to account_account_users_path(@account), notice: "User was successfully added."
      else
        redirect_to account_account_users_path(@account), alert: "Failed to add user."
      end
    end

    def destroy
      if @account_user.user_id == @account.owner_id
        redirect_to account_account_users_path(@account), alert: "The account owner cannot be removed."
      else
        @account_user.destroy!

        redirect_to account_account_users_path(@account), notice: "User was successfully removed."
      end
    end

    private

    # Membership is the account's trust boundary: only the owner manages it.
    def require_owner
      return if @account.owner_id == Current.user.id

      redirect_to account_account_users_path(@account), alert: "Only the account owner can manage members."
    end

    def set_account
      @account = Current.user.accounts.find(params[:account_id])
    end

    def set_account_user
      @account_user = @account.account_users.find(params[:id])
    end

    def set_user
      @user = User.find_by(email: params[:account_user][:email])
      redirect_to account_account_users_path(@account), alert: "User not found." unless @user
    end
  end
end
