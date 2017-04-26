class CreateDonations < ActiveRecord::Migration[5.0]
  def change
    create_table :donations, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :subscription, foreign_key: true, type: :uuid, null: false
      t.string :organization_ein, index: true, null: false
      t.references :allocation, foreign_key: true, type: :uuid, null: false
      t.references :pay_in, foreign_key: true, type: :uuid, null: false
      t.references :payout, foreign_key: true, type: :uuid
      t.integer :amount_cents

      t.timestamps
    end

    add_foreign_key :donations, :organizations, column: :organization_ein, primary_key: :ein
  end
end
