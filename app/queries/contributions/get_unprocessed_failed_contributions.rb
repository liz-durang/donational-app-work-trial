module Contributions
  class GetUnprocessedFailedContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(failed_after: Time.new(0), failed_before: Float::INFINITY)
      @relation
        .where(processed_at: nil)
        .where(failed_at: failed_after..failed_before)
        .joins(donor: [:payment_methods])
        .where(payment_methods: { deactivated_at: nil, retry_count: 1..2 })
    end
  end
end
