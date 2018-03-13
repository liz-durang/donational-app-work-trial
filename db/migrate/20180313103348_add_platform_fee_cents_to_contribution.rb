class AddPlatformFeeCentsToContribution < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :platform_fee_cents, :integer, default: 0
    add_column :portfolios, :contribution_platform_fee_cents, :integer
  end
end
