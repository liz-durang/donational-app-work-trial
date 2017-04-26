class CreatePayouts < ActiveRecord::Migration[5.0]
  def change
    create_table :payouts, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :organization_ein, index: true
      t.integer :amount_cents
      t.json :receipt

      t.timestamps
    end

    add_foreign_key :payouts, :organizations, column: :organization_ein, primary_key: :ein
  end
end
