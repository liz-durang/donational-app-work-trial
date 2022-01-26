require 'stripe'

module Payments
  class GetChargeFromDispute < ApplicationQuery
    def call(account_id:, charge_id:)
      Stripe::Charge.retrieve(charge_id, { stripe_account: account_id })
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      Rails.logger.error(e)
      nil
    end
  end
end
