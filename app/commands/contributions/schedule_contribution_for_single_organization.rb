module Contributions
  class ScheduleContributionForSingleOrganization < ApplicationCommand
    required do
      model :donor
      model :organization
      integer :amount_cents, min: 100
      time :scheduled_at
    end

    optional do
      integer :tips_cents, min: 0, default: 0
    end

    def execute
      portfolio = Portfolio.create!(creator: donor).tap do |portfolio|
        Portfolios::AddOrganizationAndRebalancePortfolio.run(
          portfolio: portfolio,
          organization: organization
        )
      end

      contribution = Contribution.create!(
        donor: donor,
        portfolio: portfolio,
        amount_cents: amount_cents,
        tips_cents: tips_cents,
        scheduled_at: scheduled_at
      )
    end
  end
end
