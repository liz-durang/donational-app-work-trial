class SubscriptionsController < ApplicationController
  include Secured

  def show
    @subscription = Subscriptions::GetActiveSubscription.call(donor: current_donor)

    @allocations = Allocations::GetRecommendedAllocations.call(donor: current_donor)
  end
end
