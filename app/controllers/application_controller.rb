class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception
  before_action :validate_admin!

  # For APIs, use token based authentication
  acts_as_token_authentication_handler_for User

  def validate_admin!
    if admin_only && !current_user.admin?
      redirect_to ('/404')
    end
  end

  def admin_only
    false
  end

  def json_request?
    request.format.json?
  end
end
