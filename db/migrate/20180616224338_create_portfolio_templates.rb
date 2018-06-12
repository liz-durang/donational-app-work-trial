class CreatePortfolioTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :portfolio_templates, id: :uuid do |t|
      t.references :partner, foreign_key: true, type: :uuid
      t.string :title
      t.string :organization_eins, array: :true

      t.timestamps
    end
  end
end
