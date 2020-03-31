class RemindersMailer < ApplicationMailer
  def send_reminder(contribution, payment_method, partner)
    @contribution = contribution
    @payment_method = payment_method
    @partner_name = partner.name
    @partner = partner
    @currency = partner.currency

    Time.use_zone(contribution.donor.time_zone) do
      mail(
        to: @contribution.donor.email,
        from: "Donational Reminders <reminders@donational.org>",
        reply_to: "support@donational.org",
        subject: "Your upcoming donation to your #{@partner_name} charity portfolio"
      )
    end
  end
end
