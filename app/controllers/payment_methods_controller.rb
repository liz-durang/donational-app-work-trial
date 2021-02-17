class PaymentMethodsController < ApplicationController
  include Secured

  def create
    outcome = Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: params[:payment_token],
      payment_method_id: params[:payment_method_id]
    )

    flash[:success] = "Thanks, we've updated your payment information" if outcome.success?
    flash[:error] = outcome.errors.message_list.join('\n') unless outcome.success?
    redirect_to edit_accounts_path
  end
end
