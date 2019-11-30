class AddOperationCostsTextToPartners < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :operating_costs_text, :string
    add_column :partners, :operating_costs_organization_ein, :string
    add_foreign_key :partners, :organizations, column: :operating_costs_organization_ein, primary_key: :ein
  end
end
