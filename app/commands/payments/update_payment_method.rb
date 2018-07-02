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
          name_on_card: @response.result[:name_on_card],
          last4: @response.result[:last4]
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

    def customer_by_id
      return nil unless payment_method&.payment_processor_customer_id.present?

      find_by_id = Payments::FindCustomerById.run(customer_id: payment_method.payment_processor_customer_id)
      return nil unless find_by_id.success?
      find_by_id.result
    end

    def create_customer
      create_customer = Payments::CreateCustomer.run
      return nil unless create_customer.success?
      create_customer.result
    end

    def deactivate_existing_payment_method!
      payment_method&.update!(deactivated_at: Time.zone.now)
    end
  end
end
