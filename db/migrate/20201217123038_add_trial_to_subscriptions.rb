class AddTrialToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :trial_start_at, :datetime
    add_column :subscriptions, :trial_last_scheduled_at, :datetime
    add_column :subscriptions, :trial_deactivated_at, :datetime
    add_column :subscriptions, :trial_amount_cents, :integer

    add_index :subscriptions, :trial_deactivated_at
  end
end
