module Contributions
  class SendFutureDatedContributionsReminder < ApplicationCommand
    def execute
      contributions = Contributions::GetContributionsWhichNeedReminder.call
      contributions.each do |contribution|
        payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)
        entity = get_entity_from_portfolio(contribution)

        RemindersMailer.send_reminder(contribution, payment_method, entity).deliver_now
      end

      nil
    end

    private

    def get_entity_from_portfolio(contribution)
      portfolio ||= Portfolios::GetActivePortfolio.call(donor: contribution.donor)
      managed_portfolio ||= Portfolios::GetManagedPortfolio.call(portfolio: portfolio)

      entity = managed_portfolio.present? ? managed_portfolio.partner.name : "Donational.org"
    end
  end
end
