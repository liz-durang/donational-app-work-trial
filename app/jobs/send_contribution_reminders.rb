class SendContributionReminders < ApplicationJob
  include ScheduledToRepeat

  def perform
    remindable_contributions.each do |contribution|
      payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)

      portfolio_manager = Portfolios::GetPortfolioManager.call(portfolio: contribution.portfolio)

      RemindersMailer.send_reminder(contribution, payment_method, portfolio_manager).deliver_now

      contribution.update!(last_reminded_at: Time.zone.now)
    end

    nil
  end

  private

  def remindable_contributions
    Contributions::GetContributionsWhichNeedReminder.call
  end
end
