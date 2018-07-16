require 'stripe'

module Payments
  class FindCustomerById < ApplicationCommand
    required do
      string :customer_id
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      response = Stripe::Customer.retrieve(customer_id)
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
