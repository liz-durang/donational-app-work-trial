module Subscriptions
  class GetActiveSubscription < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(donor:)
      GetActiveSubscriptions.new(@relation).call(donor: donor).first
    end
  end
end
