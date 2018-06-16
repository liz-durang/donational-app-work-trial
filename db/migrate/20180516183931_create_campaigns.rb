class CreateCampaigns < ActiveRecord::Migration[5.1]
  def change
    create_table :campaigns, id: :uuid do |t|
      t.references :partner, foreign_key: true, type: :uuid
      t.string :title
      t.text :description
      t.string :slug
      t.integer :target_amount_cents
      t.string :default_contribution_amounts, array: true

      t.timestamps
    end
  end
end
