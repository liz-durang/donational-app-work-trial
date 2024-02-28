module Payments
  module ConnectedAccount
    # Keep these methods separate for readability as we only have a handful of ACSS users to date
    module AcssDebitSupport
      class MandateNotFound < Stripe::StripeError
        def initialize(msg = 'Stripe mandate not found')
          super
        end
      end

      protected

      # acss_estimate_payment_processor_fees_cents will only be correct if we're working in CAD.
      def validate_acss_currency!
        return unless !/cad/i.match?(currency) && payment_method_type == 'acss_debit'

        add_error(:customer, :payment_error, 'Invalid ACSS currency')
      end

      def acss_mandate_id
        return unless payment_method_type == 'acss_debit'

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

      # This generates an estimate of the stripe fees, since, for ACSS debit payments, we can't get them until the
      # payment is done processing
      def acss_estimate_payment_processor_fees_cents
        # As per Stripe docs, their fee is: 1% + C$0.40 capped at C$5
        pct_fee = (40 + (0.01 * donation_amount_cents)).round
        [500, pct_fee].min
      end
    end
  end
end
