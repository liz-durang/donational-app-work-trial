class AddDeactivatedAtToDonors < ActiveRecord::Migration[5.2]
  def change
    add_column :donors, :deactivated_at, :datetime
  end
end
