require 'stripe'

module Payments
  class UpdateCustomerAcssDebitDetails < ApplicationCommand
    required do
      string :customer_id
      string :payment_method_id
      string :donor_id
      string :account_id
    end

    def execute
      # Make sure to set donor_id on the stripe customer. Not done when customer is first created.
      Stripe::Customer.update(customer_id, { metadata: { donor_id: donor_id } }, { stripe_account: account_id })

      payment_method = begin
        Stripe::PaymentMethod.attach(payment_method_id, { customer: customer_id }, { stripe_account: account_id })
      rescue Stripe::InvalidRequestError # Unverified payment methods will throw this (micro-deposits flow)
        Stripe::PaymentMethod.retrieve(payment_method_id, { stripe_account: account_id })
      end

      OpenStruct.new(
        address_zip_code: payment_method[:billing_details][:address][:postal_code],
        institution: payment_method[:acss_debit][:bank_name],
        last4: payment_method[:acss_debit][:last4],
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
