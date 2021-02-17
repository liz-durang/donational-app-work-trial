require 'stripe'

module Payments
  class GenerateSetupIntentClientSecret < ApplicationQuery
    def call
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      setup_intent = Stripe::SetupIntent.create
      setup_intent[:client_secret]
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      nil
    end
  end
end
