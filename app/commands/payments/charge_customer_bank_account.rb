require 'stripe'

module Payments
  class ChargeCustomerBankAccount < ApplicationCommand
    required do
      string :account_id, empty: false
      string :currency, empty: false
      integer :donation_amount_cents
      model :payment_method
    end

    optional do
      hash :metadata do
        string :donor_id
        string :portfolio_id
        string :contribution_id
      end
      integer :platform_fee_cents, default: 0
      integer :tips_cents, default: 0
    end

    def execute
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

      token = Stripe::Token.create(
        { customer: payment_method.payment_processor_customer_id },
        { stripe_account: account_id }
      )

      charge = Stripe::Charge.create(
        {
          source: token.id,
          amount: donation_amount_cents + tips_cents,
          application_fee: platform_fee_cents + tips_cents,
          currency: currency,
          expand: ['balance_transaction'],
          metadata: metadata
        },
        stripe_account: account_id
      )

      balance_transaction = charge[:balance_transaction]
      payment_processor_fees_cents = nil

      if balance_transaction.present?
        fee = balance_transaction[:fee_details].detect { |fee| fee[:type] == 'stripe_fee' }
        payment_processor_fees_cents = fee[:amount]
      end

      OpenStruct.new(
        payment_processor_fees_cents: payment_processor_fees_cents,
        receipt: charge
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)

      nil
    end
  end
end
