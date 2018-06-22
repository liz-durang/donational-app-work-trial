module Payments
  class UpdatePaymentMethod < ApplicationCommand
    required do
      model :donor
      string :payment_token, empty: false
    end

    def execute
      unless customer
        add_error(:customer, :empty, 'Customer does not exist and could not be created')

        return
      end

      chain do
        @response = Payments::UpdateCustomerCard.run(customer_id: customer[:id], payment_token: payment_token)
      end

      PaymentMethod.transaction do
        deactivate_existing_payment_method!

        PaymentMethod.create!(
          donor: donor,
          payment_processor_customer_id: customer[:id],
          name_on_card: credit_card_data(@response).first,
          last4: credit_card_data(@response).last
        )
      end

      nil
    end

    private

    def customer
      @customer ||= (customer_by_id || create_customer)
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def credit_card_data(response)
      return response.result[:sources][:data][0][:name], response.result[:sources][:data][0][:last4]
    end

    def customer_by_id
      return nil unless payment_method&.payment_processor_customer_id.present?

      find_by_id = Payments::FindCustomerById.run(customer_id: payment_method.payment_processor_customer_id)
      return nil unless find_by_id.success?
      find_by_id.result
    end

    def create_customer
      return nil unless donor.email.present?

      create_customer = Payments::CreateCustomer.run(email: donor.email)
      return nil unless create_customer.success?
      create_customer.result
    end

    def deactivate_existing_payment_method!
      payment_method&.update!(deactivated_at: Time.zone.now)
    end
  end
end
