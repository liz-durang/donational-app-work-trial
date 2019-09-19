module Contributions
  class GetActiveRecurringContribution < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call(donor:)
      GetActiveRecurringContributions
        .new(@relation)
        .call(donor: donor)
        .order(created_at: :desc)
        .first
    end
  end
end
