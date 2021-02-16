class AddPaymentProcessorSourceIdToPaymentMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_methods, :payment_processor_source_id, :string
  end
end
