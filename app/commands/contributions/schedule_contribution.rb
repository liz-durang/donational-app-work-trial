module Contributions
  class ScheduleContribution < Mutations::Command
    required do
      model :portfolio
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      monthly_income = portfolio.annual_income_cents / 12.0
      contribution_amount_cents = (monthly_income * portfolio.donation_rate).to_i

      Contribution.create!(
        portfolio: portfolio,
        amount_cents: contribution_amount_cents,
        scheduled_at: scheduled_at
      )

      nil
    end
  end
end
