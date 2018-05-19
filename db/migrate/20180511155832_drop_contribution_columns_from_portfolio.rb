class DropContributionColumnsFromPortfolio < ActiveRecord::Migration[5.1]
  def change
    remove_column :portfolios, :contribution_amount_cents, :integer
    remove_column :portfolios, :contribution_platform_fee_cents, :integer
    remove_column :portfolios, :contribution_frequency, :string
  end
end
