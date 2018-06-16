class CreatePartners < ActiveRecord::Migration[5.1]
  def change
    create_table :partners, id: :uuid do |t|
      t.string :name
      t.string :website_url
      t.text :description
      t.decimal :platform_fee_percentage, default: 0
      t.string :primary_branding_color

      t.timestamps
    end
  end
end
