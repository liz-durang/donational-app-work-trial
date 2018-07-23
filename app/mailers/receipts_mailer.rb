class ReceiptsMailer < ApplicationMailer
  def send_receipt(contribution, payment_method)
    @contribution = contribution
    @payment_method = payment_method
    mail(to: @contribution.donor.email, subject: "Your Social Good Fund Tax-Deductible Receipt")
  end
end
