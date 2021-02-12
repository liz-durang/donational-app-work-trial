class AddMinimumContributionAmountToCampaigns < ActiveRecord::Migration[5.2]
  def change
    add_column :campaigns, :minimum_contribution_amount, :integer, default: 10
  end
end
