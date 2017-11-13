class AddPaymentProcessorCustomerIdToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :payment_processor_customer_id, :string
  end
end
