module Contributions
  class GetLastDeactivatedSubscription < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor)
        .where.not(deactivated_at: nil)
        .order(deactivated_at: :desc)
        .first
    end
  end
end
