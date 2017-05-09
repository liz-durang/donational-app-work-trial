class AddIndexToSubscriptionDeactivatedAt < ActiveRecord::Migration[5.0]
  def change
    add_index :subscriptions,
      :donor_id,
      name: :index_active_subscriptions_on_donor_id,
      where: 'deactivated_at IS NULL'
  end
end
