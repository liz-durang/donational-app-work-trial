class AddProcessedAtToPayIns < ActiveRecord::Migration[5.0]
  def change
    add_column :pay_ins, :scheduled_at, :datetime, index: true
    add_column :pay_ins, :processed_at, :datetime, index: true
  end
end
