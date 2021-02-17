require 'stripe'

module Payments
  class RefundPaymentIntent < ApplicationCommand
    required do
      string :payment_intent_id, empty: false
    end

    optional do
      hash :metadata do
        string :donor_id
        string :contribution_id
      end
    end

    def execute
      begin
        Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

        Stripe::Refund.create({
          metadata: metadata,
          payment_intent: payment_intent_id
        })
      rescue Stripe::InvalidRequestError, Stripe::StripeError => e
        add_error(:customer, :stripe_error, e.message)

        nil
      end
    end
  end
end
