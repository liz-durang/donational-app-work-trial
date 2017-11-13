class RenamePayOutsToGrants < ActiveRecord::Migration[5.1]
  def change
    rename_table :pay_outs, :grants
    rename_column :donations, :pay_out_id, :grant_id
  end
end
