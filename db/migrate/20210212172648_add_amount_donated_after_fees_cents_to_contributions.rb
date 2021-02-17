class AddAmountDonatedAfterFeesCentsToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :amount_donated_after_fees_cents, :integer
  end
end
