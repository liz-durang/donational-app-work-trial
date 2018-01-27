class PaymentMethodsController < ApplicationController
  include Secured

  def edit
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def create
    outcome = save_donor_credit_card

    if outcome.success?
      Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Payment info entered')
      redirect_to contributions_path
    else
      redirect_to contributions_path, alert: outcome.errors
    end
  end

  private

  def save_donor_credit_card
    Donors::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: params[:payment_token]
    )
  end
end
