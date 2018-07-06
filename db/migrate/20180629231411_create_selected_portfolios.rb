class CreateSelectedPortfolios < ActiveRecord::Migration[5.1]
  def change
    create_table :selected_portfolios, id: :bigint do |t|
      t.references :donor, foreign_key: true, type: :uuid
      t.references :portfolio, foreign_key: true, type: :uuid
      t.datetime :deactivated_at, index: true

      t.timestamps
    end
    rename_column :portfolios, :donor_id, :creator_id
  end
end
