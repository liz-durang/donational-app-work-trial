require 'stripe'

module Payments
  class UpdateCustomerPaymentSource < ApplicationCommand
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

      source = response[:sources][:data][0]

      OpenStruct.new(
        payment_source_type: source[:object],
        name: source[:name] || source[:account_holder_name],
        institution: source[:brand] || source[:bank_name],
        last4: source[:last4],
        address_zip_code: source[:address_zip]
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
