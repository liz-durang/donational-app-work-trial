module Contributions
  class GetRecurringContributionsByFrequency < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call(frequency:)
      @relation
        .where(deactivated_at: nil)
        .where(frequency: frequency)
    end
  end
end
