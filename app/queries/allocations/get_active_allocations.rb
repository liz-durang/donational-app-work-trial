module Allocations
  class GetActiveAllocations
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = Allocation.all)
      @relation = relation
    end

    def call(subscription:)
      @relation.where(subscription: subscription, deactivated_at: nil)
    end
  end
end
