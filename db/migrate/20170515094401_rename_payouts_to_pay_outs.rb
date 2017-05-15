class RenamePayoutsToPayOuts < ActiveRecord::Migration[5.0]
  def change
    rename_table :payouts, :pay_outs
    rename_column :donations, :payout_id, :pay_out_id
  end
end
