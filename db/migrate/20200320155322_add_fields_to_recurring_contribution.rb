class AddFieldsToRecurringContribution < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_contributions, :amount_currency, :string, null: false, default: 'usd'
    add_column :recurring_contributions, :payment_processor_account_id, :string
  end
end
