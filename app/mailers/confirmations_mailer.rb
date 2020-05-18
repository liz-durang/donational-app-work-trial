class ConfirmationsMailer < ApplicationMailer
  def send_confirmation(contribution:, payment_method:, partner:, cancelation:)
    @contribution = contribution
    @payment_method = payment_method
    @partner_name = partner.name
    @partner_email_receipt_preamble = partner.email_receipt_preamble
    @partner = partner
    @cancelation = cancelation
    @currency = Money::Currency.new(partner.currency)

    Time.use_zone(contribution.donor.time_zone) do
      mail(
        to: @contribution.donor.email,
        from: "Donational Confirmations <help@donational.org>",
        reply_to: "support@donational.org",
        subject: "Your upcoming donation to your #{@partner_name} charity portfolio"
      )
    end
  end
end
