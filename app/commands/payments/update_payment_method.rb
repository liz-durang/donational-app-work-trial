module Payments
  class UpdatePaymentMethod < ApplicationCommand
    required do
      model :donor
    end

    optional do
      string :payment_method_id, empty: true
      string :payment_token, empty: true
      string :customer_id, empty: true
    end

    def execute
      if payment_method_id.blank? && payment_token.blank?
        add_error(:payment_method, :empty, 'A payment method must be provided')
        return
      end

      unless customer
        add_error(:customer, :empty, 'Customer does not exist and could not be created')
        return
      end

      outcome = update_payment_method

      unless outcome.success?
        add_error(:customer, :payment_error, 'Could not update payment method')
        return
      end

      PaymentMethod.transaction do
        deactivate_existing_payment_method!

        payment_method_type = case outcome.result[:payment_source_type]
                              when 'card'
                                PaymentMethods::Card
                              when 'bank_account', 'us_bank_account'
                                PaymentMethods::BankAccount
                              when 'acss_debit'
                                PaymentMethods::AcssDebit
                              end

        PaymentMethod.create!(
          address_zip_code: outcome.result[:address_zip_code],
          donor: donor,
          institution: outcome.result[:institution],
          last4: outcome.result[:last4],
          name: outcome.result[:name],
          payment_processor_customer_id: customer[:id],
          payment_processor_source_id: outcome.result[:payment_processor_source_id],
          type: payment_method_type
        )
      end

      TriggerPaymentMethodUpdatedWebhook.perform_async(donor.id)

      nil
    end

    private

    def update_payment_method
      if customer_id.present?
        Payments::UpdateCustomerAcssDebitDetails.run(
          customer_id: customer_id,
          payment_method_id: payment_method_id,
          donor_id: donor.id,
          account_id: account_id
        )
      elsif payment_method_id.present?
        Payments::UpdateCustomerCard.run(
          customer_id: customer[:id],
          payment_method_id: payment_method_id
        )
      else
        Payments::UpdateCustomerPaymentSource.run(
          customer_id: customer[:id],
          payment_token: payment_token
        )
      end
    end

    def customer
      @customer ||= (customer_by_id || create_customer)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def account_id
      @account_id ||= Payments::GetPaymentProcessorAccountId.call(donor: donor)
    end

    def customer_by_id
      return Stripe::Customer.new(id: customer_id) if customer_id

      return nil unless payment_method.present?

      return nil if payment_method.payment_processor_customer_id.blank?

      outcome = Payments::FindCustomerById.run(customer_id: payment_method.payment_processor_customer_id)

      return nil unless outcome.success?

      outcome.result
    end

    def create_customer
      outcome = Payments::CreateCustomer.run(metadata: { donor_id: donor.id })

      return nil unless outcome.success?

      outcome.result
    end

    def deactivate_existing_payment_method!
      payment_method&.update!(deactivated_at: Time.zone.now)
    end
  end
end
