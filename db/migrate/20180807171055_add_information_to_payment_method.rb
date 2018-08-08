class AddInformationToPaymentMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_methods, :billing_address, :string
    add_column :payment_methods, :address_city, :string
    add_column :payment_methods, :address_state, :string
    add_column :payment_methods, :address_country, :string
    add_column :payment_methods, :address_zip_code, :string
  end
end
