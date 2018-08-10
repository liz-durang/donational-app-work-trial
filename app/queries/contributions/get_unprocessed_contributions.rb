module Contributions
  class GetUnprocessedContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(scheduled_after: Time.new(0), scheduled_before: Float::INFINITY)
      @relation.where(
        processed_at: nil,
        failed_at: nil,
        scheduled_at: scheduled_after..scheduled_before
      )
    end
  end
end
