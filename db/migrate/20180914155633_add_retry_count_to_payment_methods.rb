class AddRetryCountToPaymentMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_methods, :retry_count, :integer, default: 0
  end
end
