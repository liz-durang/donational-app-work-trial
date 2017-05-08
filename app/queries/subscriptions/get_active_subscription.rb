module Subscriptions
  class GetActiveSubscription
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      @relation
        .where(donor: donor, deactivated_at: nil)
        .first
    end
  end
end
