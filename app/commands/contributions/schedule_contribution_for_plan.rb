module Contributions
  class ScheduleContributionForPlan < ApplicationCommand
    required do
      model :recurring_contribution
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      chain Contributions::ScheduleContribution.run(
        donor: recurring_contribution.donor,
        portfolio: recurring_contribution.portfolio,
        amount_cents: recurring_contribution.amount_cents,
        tips_cents: recurring_contribution.tips_cents,
        scheduled_at: Time.zone.now
      )

      recurring_contribution.update!(last_scheduled_at: Time.zone.now) unless has_errors?

      nil
    end
  end
end
