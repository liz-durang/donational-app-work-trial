module Contributions
  class GetContributionsWhichNeedReminder < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call
      @relation
        .where(deactivated_at: nil)
        .where(start_at: Date.today + 7.days)
    end
  end
end
