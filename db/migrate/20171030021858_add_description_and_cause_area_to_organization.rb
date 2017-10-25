class AddDescriptionAndCauseAreaToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :description, :text
    add_column :organizations, :cause_area, :string
  end
end
