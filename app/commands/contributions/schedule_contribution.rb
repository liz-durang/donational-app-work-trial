module Contributions
  class ScheduleContribution < Mutations::Command
    required do
      model :portfolio
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      Contribution.create!(
        portfolio: portfolio,
        amount_cents: portfolio.contribution_amount_cents,
        platform_fee_cents: portfolio.contribution_platform_fee_cents,
        scheduled_at: scheduled_at
      )

      nil
    end
  end
end
