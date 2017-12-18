class AddDeactivatedAtToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :deactivated_at, :datetime
  end
end
