class AddDisputedAtToContributions < ActiveRecord::Migration[6.1]
  def change
    add_column :contributions, :disputed_at, :datetime
  end
end
