module Contributions
  class GetActiveSubscription < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      GetActiveSubscriptions
        .new(@relation)
        .call(donor: donor)
        .order(created_at: :desc)
        .first
    end
  end
end
