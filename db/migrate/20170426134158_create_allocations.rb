class CreateAllocations < ActiveRecord::Migration[5.0]
  def change
    create_table :allocations, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :subscription, foreign_key: true, type: :uuid
      t.string :organization_ein, index: true
      t.integer :percentage
      t.timestamp :deactivated_at

      t.timestamps
    end

    add_foreign_key :allocations, :organizations, column: :organization_ein, primary_key: :ein
  end
end
