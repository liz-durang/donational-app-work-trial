class SubscriptionsController < ApplicationController
  include Secured

  def new
    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end

  def create
    Subscriptions::CreateOrReplaceSubscription.run!(
      donor: current_donor,
      donation_rate: current_donor.donation_rate,
      annual_income_cents: current_donor.annual_income_cents
    )

    Allocations::UpdateAllocations.run!(
      subscription: active_subscription,
      allocations: params[:allocations].values
    )

    redirect_to subscription_path
  end

  def show
    @allocations = Allocations::GetActiveAllocations.call(subscription: active_subscription)
  end

  private

  def active_subscription
    @active_subscription ||= Subscriptions::GetActiveSubscription.call(donor: current_donor)
  end
end
