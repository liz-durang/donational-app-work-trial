require 'stripe'

module Payments
  class RefundCharge < ApplicationCommand
    required do
      string  :charge_id,   empty: false
      string  :account_id,  empty: false
    end

    def execute
      begin
        Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

        refund = Stripe::Refund.create(
          {
            charge: charge_id
          },
          stripe_account: account_id
        )
      rescue Stripe::InvalidRequestError, Stripe::StripeError => e
        add_error(:customer, :stripe_error, e.message)

        nil
      end
    end
  end
end
