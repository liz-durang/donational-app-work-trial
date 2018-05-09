module Contributions
  class GetUnprocessedContributions < ApplicationQuery
    def initialize(relation = Contribution.all)
      @relation = relation
    end

    def call(donor:, scheduled_after: Time.new(0))
      @relation.where(
        processed_at: nil,
        failed_at: nil,
        donor: donor,
        scheduled_at: scheduled_after..Float::INFINITY
      )
    end
  end
end
