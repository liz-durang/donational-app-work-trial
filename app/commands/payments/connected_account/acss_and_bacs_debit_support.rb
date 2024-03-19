module Payments
  module ConnectedAccount
    module AcssAndBacsDebitSupport
      class MandateNotFound < Stripe::StripeError
        def initialize(msg = 'Stripe mandate not found')
          super
        end
      end

      protected

      # estimate_payment_processor_fees_cents will only be correct if we're working in the correct currency.
      def validate_currency!
        case payment_method_type
        when 'acss_debit'
          return if /cad/i.match?(currency)
        when 'bacs_debit'
          return if /gbp/i.match?(currency)
        else
          return
        end

        add_error(:customer, :payment_error, "Invalid currency for #{payment_method_type}")
      end

      def mandate_id
        return unless %w[acss_debit bacs_debit].include?(payment_method_type)

        # List setup intents, to get corresponding mandate id
        mandate_id = Stripe::SetupIntent.list(
          {
            customer: payment_method.payment_processor_customer_id,
            payment_method: payment_method.payment_processor_source_id
          },
          { stripe_account: account_id }
        ).data.first.try('mandate')
        raise MandateNotFound unless mandate_id

        mandate_id
      end

      # This generates an estimate of the stripe fees, since, for ACSS and BACS debit payments, we can't get them until
      # the payment is done processing
      def estimate_payment_processor_fees_cents
        case payment_method_type
        when 'acss_debit'
          # As per Stripe docs, their fee is: 1% + C$0.40 capped at C$5
          # https://stripe.com/en-gb-ca/pricing/local-payment-methods
          pct_fee = (40 + (0.01 * donation_amount_cents)).round
          [500, pct_fee].min
        when 'bacs_debit'
          # As per Stripe docs, their fee is: 1% + £0.20 capped at £2
          # https://stripe.com/gb/pricing/local-payment-methods
          # Cap is 200 before June 1st 2024 and 400 afterwards https://support.stripe.com/questions/june-2024-pricing-updates-for-bacs-direct-debit?locale=en-GB
          cap = Date.current.before?(Date.parse('2024-06-01')) ? 200 : 400
          pct_fee = (20 + (0.01 * donation_amount_cents)).round
          [cap, pct_fee].min
        end
      end
    end
  end
end
