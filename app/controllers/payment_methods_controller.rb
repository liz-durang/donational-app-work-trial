class PaymentMethodsController < ApplicationController
  include Secured

  def create
    Payments::UpdatePaymentMethod.run!(
      donor: current_donor,
      payment_token: params[:payment_token],
      name_on_card: params[:name_on_card],
      last4: params[:last4]
    )

    flash[:success] = "Thanks, we've updated your payment information"
    redirect_to edit_accounts_path
  end
end
