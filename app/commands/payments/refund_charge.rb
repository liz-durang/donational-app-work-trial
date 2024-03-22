require 'stripe'

module Payments
  class RefundCharge < ApplicationCommand
    required do
      string :account_id, empty: false
      string :charge_id, empty: false
      integer :application_fee_amount_cents, empty: false
    end

    optional do
      hash :metadata do
        string :donor_id
        string :contribution_id
      end
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      Stripe::Refund.create(
        {
          charge: charge_id,
          refund_application_fee: application_fee_amount_cents.positive?,
          metadata:
        },
        stripe_account: account_id
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
