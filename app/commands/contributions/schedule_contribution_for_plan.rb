module Contributions
  class ScheduleContributionForPlan < ApplicationCommand
    required do
      model :subscription
      time :scheduled_at
    end

    def execute
      chain {
        Contributions::ScheduleContribution.run(
          donor: subscription.donor,
          portfolio: subscription.portfolio,
          amount_cents: subscription.amount_cents,
          tips_cents: subscription.tips_cents,
          scheduled_at: Time.zone.now,
          partner: subscription.partner,
          partner_contribution_percentage: subscription.partner_contribution_percentage
        )
      }

      subscription.update!(last_scheduled_at: Time.zone.now) unless has_errors?

      nil
    end
  end
end
