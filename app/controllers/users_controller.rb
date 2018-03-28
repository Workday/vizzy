class UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy, :show_authentication_token, :revoke_authentication_token]

  def index
    @users = User.all
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_back fallback_location: root_path, notice: "Successfully updated #{@user.display_name}"
    else
      redirect_back fallback_location: root_path, notice: "Error while updating: #{@user.errors}"
    end
  end

  def destroy
    display_name = @user.delete
    @user.delete
    redirect_to users_path, notice: "Successfully removed #{display_name}"
  end

  def show_authentication_token
    redirect_back fallback_location: root_path, notice: "Authentication Token: #{@user.authentication_token}"
  end

  def revoke_authentication_token
    @user.authentication_token = Devise.friendly_token
    @user.save
    show_authentication_token
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:admin)
  end

  def admin_only
    action_name == 'update' || action_name == 'destroy'
  end
end
