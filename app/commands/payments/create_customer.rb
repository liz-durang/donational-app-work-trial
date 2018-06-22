require 'stripe'

module Payments
  class CreateCustomer < ApplicationCommand
    required do
      string :email, empty: false
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      response = Stripe::Customer.create(email: email)
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
