module Payments
  # For charging payment methods that are located on connected Stripe accounts.
  module ConnectedAccount
    class ChargeCustomer < ApplicationCommand
      include AcssDebitSupport

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
        validate_acss_currency!
      end

      def execute
        OpenStruct.new(
          payment_processor_fees_cents:,
          receipt: payment_intent
        )
      rescue Stripe::InvalidRequestError, Stripe::StripeError => e
        add_error(:customer, :stripe_error, e.message)

        nil
      end

      protected

      def payment_intent
        @payment_intent ||= Stripe::PaymentIntent.create(
          {
            amount: donation_amount_cents + tips_cents,
            application_fee_amount: platform_fee_cents + tips_cents,
            confirm: true,
            currency:,
            expand: ['charges.data.balance_transaction'],
            metadata:,
            payment_method: payment_method.payment_processor_source_id,
            customer: payment_method.payment_processor_customer_id,
            payment_method_types: [payment_method_type],
            off_session: true,
            mandate: acss_mandate_id
          },
          stripe_account: account_id
        )
      end

      def payment_method_type
        payment_method.class.payment_processor_payment_method_type_code.to_s
      end

      def payment_processor_fees_cents
        return acss_estimate_payment_processor_fees_cents if payment_method_type == 'acss_debit'
        return nil unless balance_transaction.present?

        balance_transaction[:fee_details].detect { |fee| fee[:type] == 'stripe_fee' }[:amount]
      end

      def balance_transaction
        payment_intent[:charges][:data][0][:balance_transaction]
      end
    end
  end
end
