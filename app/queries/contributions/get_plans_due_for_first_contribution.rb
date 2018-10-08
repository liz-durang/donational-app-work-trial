module Contributions
  class GetPlansDueForFirstContribution < ApplicationQuery
    def initialize(relation = RecurringContribution.all)
      @relation = relation
    end

    def call()
      @relation
        .where(deactivated_at: nil)
        .where(start_at: Time.new(0)..Time.zone.now)
        .where(last_scheduled_at: nil)
    end
  end
end
