class RenamePayInsToContributions < ActiveRecord::Migration[5.1]
  def change
    rename_table :pay_ins, :contributions
    rename_column :donations, :pay_in_id, :contribution_id
    rename_column :subscriptions, :pay_in_frequency, :contribution_frequency
  end
end
