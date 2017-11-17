class PaymentMethodsController < ApplicationController
  include Secured

  def edit
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def create
    outcome = save_donor_credit_card

    redirect_to edit_payment_methods_path, alert: outcome.errors
  end

  private

  def save_donor_credit_card
    Donors::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: params[:payment_token]
    )
  end
end
