class PaymentMethodsController < ApplicationController
  include Secured

  def new
    payment_method
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


  def active_payment_method?
    payment_method.present?
  end
  helper_method :active_payment_method?

  def payment_method
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end
end
