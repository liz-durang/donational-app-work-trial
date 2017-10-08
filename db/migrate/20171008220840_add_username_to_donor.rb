class AddUsernameToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :username, :string, index: true
  end
end
