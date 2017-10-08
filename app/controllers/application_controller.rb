class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :logged_in?
  helper_method :current_donor

  private

  def current_donor
    @current_donor ||= Donors::GetDonorById.call(id: session[:donor_id])
  end

  def log_out!
    reset_session
  end

  def log_in!(donor)
    session[:donor_id] = donor.id
  end

  def logged_in?
    current_donor.present? && current_donor.account_holder?
  end

  def not_found
    raise ActionController::RoutingError.new('Not found')
  end
end
