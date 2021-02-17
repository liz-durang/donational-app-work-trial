require 'stripe'

module Payments
  class UpdateCustomerCard < ApplicationCommand
    required do
      string :customer_id
      string :payment_method_id
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      payment_method = Stripe::PaymentMethod.attach(payment_method_id, { customer: customer_id })

      OpenStruct.new(
        address_zip_code: payment_method[:billing_details][:address][:postal_code],
        institution: payment_method[:card][:brand],
        last4: payment_method[:card][:last4],
        name: payment_method[:billing_details][:name],
        payment_processor_source_id: payment_method_id,
        payment_source_type: payment_method[:type]
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
