class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def logged_in?
    session[:userinfo].present?
  end
end
