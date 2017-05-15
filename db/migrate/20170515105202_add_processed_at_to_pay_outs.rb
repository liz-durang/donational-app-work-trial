class AddProcessedAtToPayOuts < ActiveRecord::Migration[5.0]
  def change
    add_column :pay_outs, :scheduled_at, :datetime, index: true
    add_column :pay_outs, :processed_at, :datetime, index: true
  end
end
