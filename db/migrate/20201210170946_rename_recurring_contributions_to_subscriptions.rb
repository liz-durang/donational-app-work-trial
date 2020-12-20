class RenameRecurringContributionsToSubscriptions < ActiveRecord::Migration[5.2]
  def up
    rename_table :recurring_contributions, :subscriptions
  end

  def down
    rename_table :subscriptions, :recurring_contributions
  end
end
