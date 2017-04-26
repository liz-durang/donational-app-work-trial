class CreatePayIns < ActiveRecord::Migration[5.0]
  def change
    create_table :pay_ins, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :subscription, foreign_key: true, type: :uuid
      t.integer :amount_cents
      t.json :receipt

      t.timestamps
    end
  end
end
