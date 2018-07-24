module Contributions
  class SendFutureDatedContributionsReminder < ApplicationCommand
    def execute
      contributions = Contributions::GetContributionsWhichNeedReminder.call
      contributions.each do |contribution|
        payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)
        entity = get_entity_from_portfolio(contribution)

        RemindersMailer.send_reminder(contribution, payment_method, entity).deliver_now
        contribution.update!(last_reminded_at: Time.zone.now)
      end

      nil
    end

    private

    def get_entity_from_portfolio(contribution)
      portfolio = Portfolios::GetActivePortfolio.call(donor: contribution.donor)
      portfolio_manager = Portfolios::GetPortfolioManager.call(portfolio: portfolio)

      entity = portfolio_manager.present? ? portfolio_manager.name : "Donational.org"
    end
  end
end
