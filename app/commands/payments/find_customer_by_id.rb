require 'stripe'

module Payments
  class FindCustomerById < ApplicationCommand
    required do
      string :customer_id
    end

    optional do
      string :account_id
    end

    def execute
      opts = {}
      opts[:stripe_account] = account_id if account_id.present?

      Stripe::Customer.retrieve(customer_id, opts)
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
