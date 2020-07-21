module Contributions
  class MigrateRecurringContributionToNewPartner < ApplicationCommand
    required do
      model :recurring_contribution
      model :partner
    end

    def execute
      Contributions::CreateOrReplaceRecurringContribution.run(
        donor: recurring_contribution.donor,
        portfolio: recurring_contribution.portfolio,
        partner: partner,
        frequency: recurring_contribution.frequency,
        start_at: recurring_contribution.start_at,
        amount_cents: recurring_contribution.amount_cents,
        tips_cents: recurring_contribution.tips_cents,
        partner_contribution_percentage: recurring_contribution.partner_contribution_percentage,
        migration: true)
      nil
    end

  end
end
