require 'stripe'

module Payments
  class ChargeCustomerAcssDebit < ApplicationCommand
    MandateNotFound = Class.new(StandardError)

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

    def validate
      validate_currency!
    end

    def execute
      OpenStruct.new(
        receipt: payment_intent,
        payment_processor_fees_cents: estimate_payment_processor_fees_cents
      )
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      add_error(:customer, :stripe_error, e.message)
      nil
    rescue MandateNotFound
      add_error(:customer, :stripe_error, 'Stripe mandate not found')
      nil
    end

    protected

    def validate_currency!
      add_error(:customer, :payment_error, 'Invalid ACSS currency') unless /cad/i.match?(currency)
    end

    def payment_intent
      @payment_intent ||= Stripe::PaymentIntent.create(
        {
          payment_method_types: ['acss_debit'],
          payment_method: payment_method.payment_processor_source_id,
          customer: payment_method.payment_processor_customer_id,
          mandate: mandate_id,
          expand: ['charges.data.balance_transaction'],
          metadata: metadata,
          confirm: true,
          amount: donation_amount_cents + tips_cents,
          application_fee_amount: platform_fee_cents + tips_cents,
          currency: currency
        },
        { stripe_account: account_id }
      )
    end

    # This generates an estimate of the stripe fees,
    # as we can't get them until the payment is done processing
    def estimate_payment_processor_fees_cents
      # As per Stripe docs, their fee is: 1% + C$0.40 capped at C$5
      pct_fee = (40 + 0.01 * donation_amount_cents).round
      [500, pct_fee].min
    end

    def mandate_id
      # List setup intents, to get corresponding mandate id
      setup_intents = Stripe::SetupIntent.list(
        { customer: payment_method.payment_processor_customer_id },
        { stripe_account: account_id }
      )
      setup_intent = setup_intents.find { |si| si['payment_method'] == payment_method.payment_processor_source_id }
      raise MandateNotFound unless setup_intent
      setup_intent['mandate']
    end
  end
end
