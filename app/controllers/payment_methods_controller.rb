class PaymentMethodsController < ApplicationController
  include Secured

  def new
    @view_model = OpenStruct.new(
      active_payment_method: active_payment_method,
      payment_methods_path: payment_methods_path
    )
  end

  def create
    Payments::UpdatePaymentMethod.run!(
      donor: current_donor,
      payment_token: params[:payment_token],
      name_on_card: params[:name_on_card],
      last4: params[:last4]
    )

    flash[:success] = "Thanks, we've updated your payment information"
    redirect_to new_payment_methods_path
  end

  private

  def active_payment_method
    @active_payment_method ||= Payments::GetActivePaymentMethod.call(donor: current_donor)
  end
end
