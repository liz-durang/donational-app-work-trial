class AddTimestampsToPaymentMethod < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :payment_methods, default: Time.zone.now
  end
end
