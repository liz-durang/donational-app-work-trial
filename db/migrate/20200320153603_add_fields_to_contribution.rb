class AddFieldsToContribution < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :amount_currency, :string, null: false, default: 'usd'
    add_column :contributions, :payment_processor_account_id, :string
  end
end
