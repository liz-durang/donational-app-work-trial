require Rails.root.join('lib','mutations','symbol_filter')

module Contributions
  class DeactivateRecurringContribution < ApplicationCommand
    required do
      model :recurring_contribution
    end

    def execute
      recurring_contribution.update!(deactivated_at: Time.zone.now)

      send_confirmation_email!
      TriggerRecurringContributionCancelledWebhook.perform_async(recurring_contribution.id, recurring_contribution.partner.id)

      nil
    end

    private

    def send_confirmation_email!
      payment_method = Payments::GetActivePaymentMethod.call(donor: recurring_contribution.donor)
      portfolio_manager = Portfolios::GetPortfolioManager.call(portfolio: recurring_contribution.portfolio)

      ConfirmationsMailer.send_confirmation(
        contribution: recurring_contribution,
        payment_method: payment_method,
        partner: portfolio_manager,
        cancelation: true
      ).deliver_now
    end
  end
end
