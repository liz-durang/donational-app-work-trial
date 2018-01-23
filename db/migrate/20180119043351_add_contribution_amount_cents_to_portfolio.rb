class AddContributionAmountCentsToPortfolio < ActiveRecord::Migration[5.1]
  def change
    add_column :portfolios, :contribution_amount_cents, :integer
  end
end
