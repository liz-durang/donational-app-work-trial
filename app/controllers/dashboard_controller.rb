class DashboardController < ApplicationController
  before_action :ensure_current_donor!, only: :show

  layout 'minimal'

  private

  def ensure_current_donor!
    return if current_donor

    new_donor = Donors::Create.run!

    log_in! new_donor
  end
end
