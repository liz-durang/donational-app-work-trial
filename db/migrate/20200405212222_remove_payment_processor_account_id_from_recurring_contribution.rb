# frozen_string_literal: true

class RemovePaymentProcessorAccountIdFromRecurringContribution < ActiveRecord::Migration[5.2]
  def change
    remove_column :recurring_contributions, :payment_processor_account_id, :string
  end
end
