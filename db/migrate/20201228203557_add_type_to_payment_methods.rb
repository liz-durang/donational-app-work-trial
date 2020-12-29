class AddTypeToPaymentMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_methods, :type, :string, default: 'PaymentMethods::Card'
    rename_column :payment_methods, :name_on_card, :name
    add_column :payment_methods, :institution, :string
  end
end
