class AddUniqueIndexToUsernameInDonors < ActiveRecord::Migration[5.1]
  def change
    add_index :donors, :username, unique: true
  end
end
