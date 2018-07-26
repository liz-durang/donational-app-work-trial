class AddLastRemindedAtToRecurringContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :recurring_contributions, :last_reminded_at, :datetime
  end
end
