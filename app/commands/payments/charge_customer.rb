require 'stripe'

module Payments
  class ChargeCustomer < ApplicationCommand
    required do
      string :customer_id, empty: false
      string :account_id, empty: false
      string :email, empty: false
      integer :donation_amount_cents
    end

    optional do
      integer :platform_fee_cents, default: 0
      integer :tips_cents, default: 0
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      charge = Stripe::Charge.create(
        {
          customer: customer_id,
          amount: donation_amount_cents + tips_cents,
          application_fee: platform_fee_cents + tips_cents,
          currency: 'usd',
          receipt_email: email
        },
        stripe_account: account_id
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
