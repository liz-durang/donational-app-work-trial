class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :donor, foreign_key: true, type: :uuid
      t.integer :annual_income_cents
      t.decimal :donation_rate
      t.string :pay_in_frequency
      t.timestamp :deactivated_at

      t.timestamps
    end
  end
end
