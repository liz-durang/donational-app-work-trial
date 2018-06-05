class CreatePaymentMethods < ActiveRecord::Migration[5.1]
  def change
    create_table :payment_methods, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :donor, foreign_key: true, type: :uuid, null: false
      t.string :payment_processor_customer_id
      t.string :name_on_card
      t.string :last4
      t.datetime :deactivated_at, index: true
    end
  end
end
