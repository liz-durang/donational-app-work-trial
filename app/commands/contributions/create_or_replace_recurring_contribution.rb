require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class CreateOrReplaceRecurringContribution < ApplicationCommand
    required do
      model :donor
      model :portfolio
      model :partner
      symbol :frequency, default: :monthly, in: RecurringContribution.frequency.values
      integer :amount_cents, min: 0
      integer :tips_cents, min: 0, default: 0
    end

    optional do
      time :start_at
      integer :partner_contribution_percentage, min: 0, default: 0
    end

    def execute
      RecurringContribution.transaction do
        # ensure we don't force a new donation when donor updates their plan settings
        most_recent_last_scheduled_at = previous_plans_most_recent_scheduled_at
        deactivate_existing_recurring_contributions!
        recurring_contribution = RecurringContribution.create!(
          donor: donor,
          portfolio: portfolio,
          partner: partner,
          frequency: frequency,
          start_at: start_at || Time.zone.now,
          amount_cents: amount_cents,
          tips_cents: tips_cents,
          last_scheduled_at: frequency == :once ? nil : most_recent_last_scheduled_at,
          partner_contribution_percentage: partner_contribution_percentage,
          amount_currency: partner.currency,
          payment_processor_account_id: partner.payment_processor_account_id
        )

        Portfolios::SelectPortfolio.run(donor: donor, portfolio: portfolio)

        send_confirmation_email!(recurring_contribution)

        TriggerRecurringContributionUpdatedWebhook.perform_async(recurring_contribution.id, partner.id)
      end

      nil
    end

    private

    def existing_recurring_contributions
      @existing_recurring_contributions ||= 
        Contributions::GetActiveRecurringContributions.call(donor: donor)
    end

    def previous_plans_most_recent_scheduled_at
      existing_recurring_contributions.maximum(:last_scheduled_at)
    end

    def deactivate_existing_recurring_contributions!
      existing_recurring_contributions.update_all(deactivated_at: Time.zone.now)
    end

    def send_confirmation_email!(recurring_contribution)
      payment_method = Payments::GetActivePaymentMethod.call(donor: recurring_contribution.donor)
      partner = Partners::GetPartnerForDonor.call(donor: recurring_contribution.donor)

      ConfirmationsMailer.send_confirmation(
        contribution: recurring_contribution,
        payment_method: payment_method,
        partner: partner,
        cancelation: false
      ).deliver_now
    end
  end
end
