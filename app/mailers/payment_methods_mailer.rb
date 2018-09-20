class PaymentMethodsMailer < ApplicationMailer
  def send_payment_failed(contribution, payment_method, partner)
    @contribution = contribution
    @payment_method = payment_method
    @partner_name = partner.try(:name) || "Donational.org"
    @partner = partner

    Time.use_zone(contribution.donor.time_zone) do
      mail(
        to: @contribution.donor.email,
        from: "Donational Payments <help@donational.org>",
        reply_to: "support@donational.org",
        subject: "Your Donation to your #{@partner_name} charity portfolio could not be processed"
      )
    end
  end
end
