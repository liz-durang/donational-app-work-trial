class AddFeesToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :platform_fees_cents, :integer
    add_column :contributions, :donor_advised_fund_fees_cents, :integer
  end
end
