module Subscriptions
  class GetActiveSubscriptions < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(donor: donor, deactivated_at: nil)
    end
  end
end
