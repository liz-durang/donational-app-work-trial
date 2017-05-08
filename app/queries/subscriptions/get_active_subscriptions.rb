module Subscriptions
  class GetActiveSubscriptions
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(donor: donor, deactivated_at: nil)
    end
  end
end
