class AddDisplayOrderToManagedPortfolio < ActiveRecord::Migration[5.2]
  def change
    add_column :managed_portfolios, :display_order, :integer
  end
end
