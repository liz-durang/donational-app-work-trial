class AddFilterCriteriaToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :local_impact, :boolean
    add_column :organizations, :global_impact, :boolean
    add_column :organizations, :immediate_impact, :boolean
    add_column :organizations, :long_term_impact, :boolean
  end
end
