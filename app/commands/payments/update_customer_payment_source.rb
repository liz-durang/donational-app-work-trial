require 'stripe'

module Payments
  class UpdateCustomerPaymentSource < ApplicationCommand
    required do
      string :customer_id
      string :payment_token
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      customer = Stripe::Customer.update(
        customer_id,
        {
          expand: ['sources'],
          source: payment_token
        }
      )
      source = customer[:sources][:data][0]

      OpenStruct.new(
        address_zip_code: source[:address_zip],
        institution: source[:bank_name],
        last4: source[:last4],
        name: source[:account_holder_name],
        payment_processor_source_id: source[:id],
        payment_source_type: source[:object]
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
