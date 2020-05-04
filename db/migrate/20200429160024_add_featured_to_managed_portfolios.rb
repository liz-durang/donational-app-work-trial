class AddFeaturedToManagedPortfolios < ActiveRecord::Migration[5.2]
  def change
    add_column :managed_portfolios, :featured, :boolean, null:false, default: false
  end
end
