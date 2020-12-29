class SendContributionReminders < ApplicationJob
  include ScheduledToRepeat

  def perform
    remindable_subscriptions.each do |subscription|
      payment_method = Payments::GetActivePaymentMethod.call(donor: subscription.donor)
      partner = Partners::GetPartnerForDonor.call(donor: subscription.donor)
      RemindersMailer.send_reminder(subscription, payment_method, partner).deliver_now

      subscription.update!(last_reminded_at: Time.zone.now)
    end

    nil
  end

  private

  def remindable_subscriptions
    Contributions::GetSubscriptionsWhichNeedReminder.call
  end
end
