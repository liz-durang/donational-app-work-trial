class ReceiptsMailer < ApplicationMailer
  def send_receipt(contribution, payment_method, partner)
    @contribution = contribution
    @payment_method = payment_method
    @partner_name = partner.name
    @partner_email_receipt_preamble = partner.email_receipt_preamble
    @partner = partner
    @currency = partner.currency
    @currency_downcase = partner.currency.downcase

    Time.use_zone(contribution.donor.time_zone) do
      mail(
        to: @contribution.donor.email,
        from: "Donational Receipts <receipts@donational.org>",
        reply_to: "support@donational.org",
        subject: "Your Tax-Deductible Receipt for your #{@partner_name} charity portfolio"
      )
    end
  end
end
