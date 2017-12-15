class AddGivingChallengesToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :giving_challenges, :string, array: true, default: '{}'
  end
end
