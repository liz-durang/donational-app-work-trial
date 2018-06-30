class CreateManagedPortfolios < ActiveRecord::Migration[5.1]
  def change
    create_table :managed_portfolios, id: :uuid do |t|
      t.references :partner, foreign_key: true, type: :uuid
      t.references :portfolio, foreign_key: true, type: :uuid
      t.string :name
      t.text :description
      t.datetime :hidden_at

      t.timestamps
    end
  end
end
