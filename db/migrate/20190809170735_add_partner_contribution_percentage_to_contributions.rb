class AddPartnerContributionPercentageToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :partner_contribution_percentage, :integer, default: 0
    add_column :recurring_contributions, :partner_contribution_percentage, :integer, default: 0
  end
end
