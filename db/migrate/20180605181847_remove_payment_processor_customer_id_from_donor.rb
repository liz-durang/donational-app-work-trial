class RemovePaymentProcessorCustomerIdFromDonor < ActiveRecord::Migration[5.1]
  def change
    remove_column :donors, :payment_processor_customer_id, :string
  end
end
