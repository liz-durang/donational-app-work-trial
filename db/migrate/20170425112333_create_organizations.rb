class CreateOrganizations < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations, id: false do |t|
      t.string :ein, null: false
      t.string :name

      t.timestamps
    end
    add_index :organizations, :ein, unique: true
  end
end
