class AddDeactivatedAtToPartners < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :deactivated_at, :datetime
  end
end
