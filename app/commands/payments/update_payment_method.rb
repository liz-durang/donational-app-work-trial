module Payments
  class UpdatePaymentMethod < ApplicationCommand
    required do
      model :donor do
        string :email, empty: false
      end
      string :payment_token, empty: false
      string :name_on_card
      string :last4
    end

    def execute
      unless customer
        add_error(:customer, :empty, 'Customer does not exist and could not be created')
        return
      end

      PaymentMethod.transaction do
        deactivate_existing_payment_method!

        PaymentMethod.create!(
          donor: donor,
          payment_processor_customer_id: customer[:id],
          name_on_card: name_on_card,
          last4: last4
        )
      end

      chain do
        Payments::UpdateCustomerCard.run(customer_id: customer[:id], payment_token: payment_token)
      end

      nil
    end

    private

    def customer
      @customer ||= (customer_by_id || create_customer || customer_by_email)
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

    def customer_by_email
      return nil unless donor.email.present?

      find_by_email = Payments::FindCustomerByEmail.run(email: donor.email)
      return nil unless find_by_email.success?
      find_by_email.result
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
