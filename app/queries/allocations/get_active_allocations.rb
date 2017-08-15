module Allocations
  class GetActiveAllocations < ApplicationQuery
    def initialize(relation = Allocation.all)
      @relation = relation
    end

    def call(subscription:)
      @relation.where(subscription: subscription, deactivated_at: nil)
    end
  end
end
