module Contributions
  class GetActiveRecurringContributions < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(donor: donor, deactivated_at: nil)
    end
  end
end
