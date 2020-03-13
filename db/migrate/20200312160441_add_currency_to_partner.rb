class AddCurrencyToPartner < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :currency, :string, null: false, default: 'usd'
  end
end
