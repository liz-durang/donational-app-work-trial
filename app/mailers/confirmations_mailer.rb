class ConfirmationsMailer < ApplicationMailer
  def send_confirmation(subscription:, payment_method:, partner:, cancelation:)
    @subscription = subscription
    @payment_method = payment_method
    @partner_name = partner.name
    @partner_email_receipt_preamble = partner.email_receipt_preamble
    @partner = partner
    @cancelation = cancelation
    @currency = Money::Currency.new(partner.currency)
    @currency_downcase = partner.currency.downcase

    Time.use_zone(subscription.donor.time_zone) do
      mail(
        to: @subscription.donor.email,
        from: 'Donational Confirmations <help@donational.org>',
        reply_to: 'support@donational.org',
        subject: "Your upcoming donation to your #{@partner_name} charity portfolio"
      )
    end
  end
end
