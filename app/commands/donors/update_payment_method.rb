module Donors
  class UpdatePaymentMethod < Mutations::Command
    required do
      model :donor do
        string :email, empty: false
      end
      string :payment_token, empty: false
    end

    def execute
      create_customer = Payments::CreateCustomer.run(
        email: donor.email,
        payment_token: payment_token
      )

      if create_customer.success?
        donor.update!(payment_processor_customer_id: create_customer.result)
      end

      nil
    end
  end
end
