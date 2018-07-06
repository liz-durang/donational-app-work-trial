class RemovePortfolioTemplates < ActiveRecord::Migration[5.1]
  def up
    drop_table :portfolio_templates
  end
end
