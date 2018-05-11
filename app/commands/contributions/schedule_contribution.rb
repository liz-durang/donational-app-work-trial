module Contributions
  class ScheduleContribution < ApplicationCommand
    required do
      model :donor
      model :portfolio
      integer :amount_cents, min: 100
      time :scheduled_at, after: Time.zone.now
    end

    optional do
      integer :platform_fee_cents, min: 0, default: 0
    end

    def execute
      contribution = Contribution.create!(
        donor: donor,
        portfolio: portfolio,
        amount_cents: amount_cents,
        platform_fee_cents: platform_fee_cents,
        scheduled_at: scheduled_at
      )
    end

  end
end
