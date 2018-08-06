class ReceiptsMailer < ApplicationMailer
  def send_receipt(contribution, payment_method)
    @contribution = contribution
    @payment_method = payment_method
    mail(
      to: @contribution.donor.email,
      from: "receipts@donational.org",
      reply_to: "support@donational.org",
      subject: "Your Social Good Fund Tax-Deductible Receipt"
    )
  end
end
