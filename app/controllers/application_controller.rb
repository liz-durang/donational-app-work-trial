class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :store_current_donor_in_session, if: :logged_in?

  private

  def current_donor
    @current_donor ||= (
      session[:donor_uuid] && Donor.find_by(id: session[:donor_uuid].to_s)
    ) || (
      session[:userinfo] && Donors::FindOrCreateFromAuth.run!(session[:userinfo])
    ) || nil
  end

  def store_current_donor_in_session
    session[:donor_uuid] ||= current_donor.id
  end

  def logged_in?
    session[:userinfo].present?
  end
end
