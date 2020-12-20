module Contributions
  class MigrateSubscriptionToNewPartner < ApplicationCommand
    required do
      model :subscription
      model :partner
    end

    def execute
      Contributions::CreateOrReplaceSubscription.run(
        donor: subscription.donor,
        portfolio: subscription.portfolio,
        partner: partner,
        frequency: subscription.frequency,
        start_at: subscription.start_at,
        amount_cents: subscription.amount_cents,
        tips_cents: subscription.tips_cents,
        partner_contribution_percentage: subscription.partner_contribution_percentage,
        migration: true)
      nil
    end

  end
end
