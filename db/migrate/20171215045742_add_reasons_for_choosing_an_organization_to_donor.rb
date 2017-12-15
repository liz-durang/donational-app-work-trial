class AddReasonsForChoosingAnOrganizationToDonor < ActiveRecord::Migration[5.1]
  def change
    add_column :donors, :reasons_why_i_choose_an_organization, :string, array: true, default: '{}'
  end
end
