class AddPortfolioDiversityToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :portfolio_diversity, :integer
  end
end
