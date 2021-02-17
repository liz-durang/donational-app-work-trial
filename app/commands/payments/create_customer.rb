require 'stripe'

module Payments
  class CreateCustomer < ApplicationCommand
    optional do
      hash :metadata do
        string :donor_id
      end
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      Stripe::Customer.create({ metadata: metadata })
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
