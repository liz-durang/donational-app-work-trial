class AddGiftAidAcceptedToDonor < ActiveRecord::Migration[5.2]
  def change
    add_column :donors, :uk_gift_aid_accepted, :boolean, null: false, default: false
  end
end
