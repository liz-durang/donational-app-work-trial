class RemoveBillingAddressFromPaymentMethod < ActiveRecord::Migration[5.2]
  def change
    remove_column :payment_methods, :billing_address, :string
    remove_column :payment_methods, :address_city, :string
    remove_column :payment_methods, :address_state, :string
    remove_column :payment_methods, :address_country, :string
  end
end
