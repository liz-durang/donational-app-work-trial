class RenameSubscriptionsToPortfolios < ActiveRecord::Migration[5.1]
  def change
    rename_table :subscriptions, :portfolios
    rename_column :donations, :subscription_id, :portfolio_id
    rename_column :allocations, :subscription_id, :portfolio_id
    rename_column :contributions, :subscription_id, :portfolio_id
  end
end
