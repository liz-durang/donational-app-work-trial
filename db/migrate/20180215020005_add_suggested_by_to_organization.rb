class AddSuggestedByToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :suggested_by_donor_id, :uuid
    add_foreign_key :organizations, :donors, column: :suggested_by_donor_id, primary_key: :id
  end
end
