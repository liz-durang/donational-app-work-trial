class AddProgramRestrictionToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :program_restriction, :string
    add_column :organizations, :routing_organization_name, :string
    remove_column :organizations, :description, :text
  end
end
