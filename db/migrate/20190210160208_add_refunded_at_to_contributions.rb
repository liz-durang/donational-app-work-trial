class AddRefundedAtToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :refunded_at, :datetime, index: true
  end
end
