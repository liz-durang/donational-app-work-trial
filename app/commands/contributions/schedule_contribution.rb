module Contributions
  class ScheduleContribution < Mutations::Command
    required do
      model :subscription
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      monthly_income = subscription.annual_income_cents / 12.0
      contribution_amount_cents = (monthly_income * subscription.donation_rate).to_i

      Contribution.create!(
        subscription: subscription,
        amount_cents: contribution_amount_cents,
        scheduled_at: scheduled_at
      )

      nil
    end
  end
end
