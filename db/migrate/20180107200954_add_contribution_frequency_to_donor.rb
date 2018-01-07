class AddContributionFrequencyToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :contribution_frequency, :string
  end
end
