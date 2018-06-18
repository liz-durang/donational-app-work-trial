class RenamePlatformFeeAsTips < ActiveRecord::Migration[5.1]
  def change
    rename_column :contributions, :platform_fee_cents, :tips_cents
    rename_column :recurring_contributions, :platform_fee_cents, :tips_cents
  end
end
