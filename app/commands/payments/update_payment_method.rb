module Payments
  class UpdatePaymentMethod < ApplicationCommand
    required do
      model :donor
    end

    optional do
      model :processor_payment_method, class: Stripe::PaymentMethod
      string :payment_method_id, empty: true
      string :payment_token, empty: true
      string :customer_id, empty: true
      boolean :is_checkout_session, default: false
    end

    def validate
      if !is_checkout_session && payment_method_id.blank? && payment_token.blank?
        add_error(:payment_method_id, :empty, 'A payment method must be provided')
        return
      end

      if is_checkout_session
        if processor_payment_method.blank?
          add_error(:processor_payment_method, :empty,
                    'A processor payment method must be provided')
        end
        add_error(:customer_id, :empty, 'A customer id must be provided') if customer_id.blank?
        return
      end

      return if customer

      add_error(:customer, :empty, 'Customer does not exist and could not be created')
      nil
    end

    def execute
      processor_payment_method_details = if is_checkout_session
                                           parse_payment_method
                                         else
                                           outcome = update_payment_method

                                           unless outcome.success?
                                             add_error(:customer, :payment_error,
                                                       'Could not update payment method on payment processor')
                                             return
                                           end

                                           outcome.result
                                         end

      PaymentMethod.transaction do
        deactivate_existing_payment_method!

        payment_source_type = case processor_payment_method_details[:payment_source_type]
                              when 'card'
                                PaymentMethods::Card
                              when 'us_bank_account', 'bank_account'
                                # Exceptionally, the Sources API uses 'bank_account', while others use 'us_bank_account'
                                # https://docs.stripe.com/api/tokens/create_bank_account
                                # https://stripe.com/docs/api/payment_methods/object#payment_method_object-type
                                PaymentMethods::BankAccount
                              when 'acss_debit'
                                PaymentMethods::AcssDebit
                              when 'bacs_debit'
                                PaymentMethods::BacsDebit
                              end

        PaymentMethod.create!(
          address_zip_code: processor_payment_method_details[:address_zip_code],
          donor:,
          institution: processor_payment_method_details[:institution],
          last4: processor_payment_method_details[:last4],
          name: processor_payment_method_details[:name],
          payment_processor_customer_id: customer[:id],
          payment_processor_source_id: processor_payment_method_details[:payment_processor_source_id],
          type: payment_source_type
        )
      end

      TriggerPaymentMethodUpdatedWebhook.perform_async(donor.id)

      nil
    end

    private

    # Update the payment method on the payment processor's side (as opposed to updating the PaymentMethod record on Donational).
    def update_payment_method
      if customer_id.present?
        Payments::UpdateCustomerAcssDebitDetails.run(
          customer_id:,
          payment_method_id:,
          donor_id: donor.id,
          account_id:
        )
      elsif payment_method_id.present?
        Payments::UpdateCustomerCard.run(
          customer_id: customer[:id],
          payment_method_id:
        )
      else
        Payments::UpdateCustomerPaymentSource.run(
          customer_id: customer[:id],
          payment_token:
        )
      end
    end

    # When using Checkout Sessions, we don't need to update the PaymentMethod on the payment processor's side, only
    # unpack the relevant data from the object.
    def parse_payment_method
      institution = processor_payment_method.type == 'card' ? :brand : :bank_name

      OpenStruct.new(
        address_zip_code: processor_payment_method[:billing_details][:address][:postal_code],
        institution: processor_payment_method[processor_payment_method.type.to_sym][institution],
        last4: processor_payment_method[processor_payment_method.type.to_sym][:last4],
        name: processor_payment_method[:billing_details][:name],
        payment_source_type: processor_payment_method.type,
        payment_processor_source_id: processor_payment_method[:id],
        payment_processor_customer_id: customer_id
      )
    end

    def customer
      @customer ||= (customer_by_id || create_customer)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor:)
    end

    def account_id
      @account_id ||= Payments::GetPaymentProcessorAccountId.call(donor:)
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
      return if is_checkout_session

      outcome = Payments::CreateCustomer.run(metadata: { donor_id: donor.id })

      return nil unless outcome.success?

      outcome.result
    end

    def deactivate_existing_payment_method!
      payment_method&.update!(deactivated_at: Time.zone.now)
    end
  end
end
