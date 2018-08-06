class RemindersMailer < ApplicationMailer
  def send_reminder(contribution, payment_method, entity)
    @contribution = contribution
    @payment_method = payment_method
    @entity = entity

    mail(
      to: @contribution.donor.email,
      from: "reminders@donational.org",
      reply_to: "support@donational.org",
      subject: "Your upcoming donation to your #{entity} charity portfolio"
    )
  end
end
