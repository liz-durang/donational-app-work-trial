class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def current_donor
    @current_donor ||= Donors::FindOrCreateDonorFromAuth.run!(session[:userinfo])
  end

  def logged_in?
    session[:userinfo].present?
  end
end
