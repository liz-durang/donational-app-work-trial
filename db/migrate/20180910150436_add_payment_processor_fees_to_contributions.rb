class AddPaymentProcessorFeesToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :payment_processor_fees_cents, :integer
  end
end
