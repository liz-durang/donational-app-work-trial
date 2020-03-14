class SendContributionReminders < ApplicationJob
  include ScheduledToRepeat

  def perform
    remindable_contributions.each do |contribution|
      payment_method = Payments::GetActivePaymentMethod.call(donor: contribution.donor)
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)
      RemindersMailer.send_reminder(contribution, payment_method, partner).deliver_now

      contribution.update!(last_reminded_at: Time.zone.now)
    end

    nil
  end

  private

  def remindable_contributions
    Contributions::GetContributionsWhichNeedReminder.call
  end
end
