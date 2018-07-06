class AddPaymentProcessorAccountIdToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :payment_processor_account_id, :string
  end
end
