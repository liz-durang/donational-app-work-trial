require 'stripe'

module Payments
  class UpdateCustomerCard < ApplicationCommand
    required do
      string :customer_id
      string :payment_token
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      response = Stripe::Customer.update(
        customer_id,
        { source: payment_token }
      )
      OpenStruct.new(
        name_on_card: response[:sources][:data][0][:name],
        last4: response[:sources][:data][0][:last4]
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
