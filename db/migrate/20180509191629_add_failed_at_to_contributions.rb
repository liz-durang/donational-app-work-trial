class AddFailedAtToContributions < ActiveRecord::Migration[5.1]
  def change
    add_column :contributions, :failed_at, :datetime
  end
end
