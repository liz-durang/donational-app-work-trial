module Contributions
  class GetSubscriptionById  < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
