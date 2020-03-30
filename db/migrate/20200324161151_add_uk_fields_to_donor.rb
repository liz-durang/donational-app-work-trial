class AddUkFieldsToDonor < ActiveRecord::Migration[5.2]
  def change
    add_column :donors, :type, :string
    add_column :donors, :title, :string
    add_column :donors, :house_name_or_number, :string
    add_column :donors, :postcode, :string
  end
end
