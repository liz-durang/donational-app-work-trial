module Contributions
  class GetSubscriptionsByFrequency < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(frequency:)
      @relation
        .where(deactivated_at: nil)
        .where(frequency: frequency)
        .where(start_at: Time.new(0)..Time.zone.now)
    end
  end
end
