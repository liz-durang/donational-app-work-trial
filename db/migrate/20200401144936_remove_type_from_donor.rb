class RemoveTypeFromDonor < ActiveRecord::Migration[5.2]
  def change
    remove_column :donors, :type, :string
  end
end
