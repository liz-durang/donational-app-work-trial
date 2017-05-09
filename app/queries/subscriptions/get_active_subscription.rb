module Subscriptions
  class GetActiveSubscription
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      GetActiveSubscriptions.new(@relation).call(donor: donor).first
    end
  end
end
