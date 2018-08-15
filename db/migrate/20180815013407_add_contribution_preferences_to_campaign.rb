class AddContributionPreferencesToCampaign < ActiveRecord::Migration[5.2]
  def change
    add_column :campaigns, :contribution_amount_help_text, :string
    add_column :campaigns, :allow_one_time_contributions, :boolean, null: false, default: true
  end
end
