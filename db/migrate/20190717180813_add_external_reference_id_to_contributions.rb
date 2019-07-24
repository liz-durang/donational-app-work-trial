class AddExternalReferenceIdToContributions < ActiveRecord::Migration[5.2]
  def change
    add_column :contributions, :external_reference_id, :string
  end
end
