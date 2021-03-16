module Contributions
  class ScheduleContributionsForPastDuePlans < ApplicationCommand
    def execute
      plans_due_for_first_contribution.each do |plan|
        Contributions::ScheduleContributionForPlan.run(
          subscription: plan,
          scheduled_at: Time.zone.now
        )
      end

      trials_due_for_first_contribution.each do |trial|
        Contributions::ScheduleContributionForTrial.run(
          subscription: trial,
          scheduled_at: Time.zone.now
        )
      end

      plans_due_subscription.each do |plan|
        Contributions::ScheduleContributionForPlan.run(
          subscription: plan,
          scheduled_at: Time.zone.now
        )
      end

      trials_due_subscription.each do |trial|
        Contributions::ScheduleContributionForTrial.run(
          subscription: trial,
          scheduled_at: Time.zone.now
        )
      end

      nil
    end

    private

    def plans_due_for_first_contribution
      Contributions::GetPlansDueForFirstContribution.call
    end

    def plans_due_subscription
      Contributions::GetPlansDueSubscription.call
    end

    def trials_due_for_first_contribution
      Contributions::GetTrialsDueForFirstContribution.call
    end

    def trials_due_subscription
      Contributions::GetTrialsDueSubscription.call
    end
  end
end
