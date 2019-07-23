class AddEntityNameToDonors < ActiveRecord::Migration[5.2]
  def change
    add_column :donors, :entity_name, :string
  end
end
