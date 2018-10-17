class AddLastScheduledAtToRecurringContribution < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_contributions, :last_scheduled_at, :datetime
  end
end
