class AddVoidedAtToGrant < ActiveRecord::Migration[5.2]
  def change
    add_column :grants, :voided_at, :datetime
  end
end
