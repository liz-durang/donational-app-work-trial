class ApplicationController < ActionController::Base
  helper_method :logged_in?
  helper_method :current_donor
  around_action :set_time_zone, if: :current_donor

  private

  def set_time_zone(&block)
    Time.use_zone(current_donor.time_zone, &block)
  end

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
