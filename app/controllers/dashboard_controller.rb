class DashboardController < ApplicationController
  before_action :ensure_current_donor!, only: :show

  layout 'minimal'

  private

  def ensure_current_donor!
    return if current_donor
    log_in! Donor.create!
  end
end
