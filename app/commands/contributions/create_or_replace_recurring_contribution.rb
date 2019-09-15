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
    end

    def execute
      RecurringContribution.transaction do
        # ensure we don't force a new donation when donor updates their plan settings
        most_recent_last_scheduled_at = previous_plans_most_recent_scheduled_at
        deactivate_existing_recurring_contributions!

        @contribution = RecurringContribution.create!(
          donor: donor,
          portfolio: portfolio,
          partner: partner,
          frequency: frequency,
          start_at: start_at || Time.zone.now,
          amount_cents: amount_cents,
          tips_cents: tips_cents,
          last_scheduled_at: frequency == 'once' ? nil : most_recent_last_scheduled_at
        )

        send_confirmation_email!
        TriggerRecurringContributionUpdatedWebhook.perform_async(@contribution.id, partner.id)
      end

      nil
    end

    private

    def existing_recurring_contributions
      Contributions::GetActiveRecurringContributions.call(donor: donor)
    end

    def previous_plans_most_recent_scheduled_at
      existing_recurring_contributions.maximum(:last_scheduled_at)
    end

    def deactivate_existing_recurring_contributions!
      existing_recurring_contributions.update_all(deactivated_at: Time.zone.now)
    end

    def send_confirmation_email!
      payment_method = Payments::GetActivePaymentMethod.call(donor: @contribution.donor)
      portfolio_manager = Portfolios::GetPortfolioManager.call(portfolio: @contribution.portfolio)

      ConfirmationsMailer.send_confirmation(
        contribution: @contribution,
        payment_method: payment_method,
        partner: portfolio_manager,
        cancelation: false
      ).deliver_now
    end
  end
end
