# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :logged_in?
  helper_method :current_donor
  helper_method :current_currency
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

  def current_currency
    return Money.default_currency unless current_donor

    currency = Partners::GetPartnerForDonor.call(donor: current_donor).currency
    Money::Currency.new(currency)
  end

  def not_found
    render status: :not_found
  end
end
