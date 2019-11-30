class MakeAllocationOptionalInDonation < ActiveRecord::Migration[5.2]
  def change
    change_column_null :donations, :allocation_id, true
  end
end
