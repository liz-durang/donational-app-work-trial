class CreateRecurringContributions < ActiveRecord::Migration[5.1]
  def change
    create_table :recurring_contributions, id: :uuid do |t|
      t.references :donor, foreign_key: true, type: :uuid
      t.references :portfolio, foreign_key: true, type: :uuid
      t.datetime :start_at, null: false
      t.datetime :deactivated_at, index: true
      t.string :frequency
      t.integer :amount_cents
      t.integer :platform_fee_cents, default: 0

      t.timestamps
    end
  end
end
