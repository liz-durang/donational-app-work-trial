module Contributions
  class ScheduleContributionsForPastDuePlans < ApplicationCommand
    def execute
      plans_due_for_first_contribution.each do |plan|
        Contributions::ScheduleContributionForPlan.run(
          recurring_contribution: plan,
          scheduled_at: Time.zone.now
        )
      end

      plans_due_recurring_contribution.each do |plan|
        Contributions::ScheduleContributionForPlan.run(
          recurring_contribution: plan,
          scheduled_at: Time.zone.now
        )
      end

      nil
    end

    private

    def plans_due_for_first_contribution
      Contributions::GetPlansDueForFirstContribution.call
    end

    def plans_due_recurring_contribution
      Contributions::GetPlansDueRecurringContribution.call
    end
  end
end
