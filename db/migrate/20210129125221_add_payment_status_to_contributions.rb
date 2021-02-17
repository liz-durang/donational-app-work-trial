class AddPaymentStatusToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :payment_status, :string, default: :unprocessed

    # Unprocessed Contributions
    Contribution.where(failed_at: nil).where(processed_at: nil).update_all(payment_status: :unprocessed)

    # Processed Contributions
    Contribution.where(failed_at: nil).where.not(processed_at: nil).update_all(payment_status: :succeeded)
    Contribution.where.not(failed_at: nil).where.not(processed_at: nil).update_all(payment_status: :succeeded)

    # Failed Contributions
    Contribution.where.not(failed_at: nil).where(processed_at: nil).update_all(payment_status: :failed)
  end
end
