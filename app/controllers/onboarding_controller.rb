class OnboardingController < ApplicationController
  before_action :ensure_current_donor!, only: :show

  layout 'onboarding'

  def show; end

  private

  def ensure_current_donor!
    return if current_donor

    new_donor = Donors::CreateAnonymousDonorAffiliatedWithPartner.run!

    log_in! new_donor
  end
end
