class AddIndexToAllocationDeactivatedAt < ActiveRecord::Migration[5.0]
  def change
    add_index :allocations,
      :subscription_id,
      name: :index_active_allocations_on_subscription_id,
      where: 'deactivated_at IS NULL'
  end
end
