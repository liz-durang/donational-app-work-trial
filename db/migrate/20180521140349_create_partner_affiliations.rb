class CreatePartnerAffiliations < ActiveRecord::Migration[5.1]
  def change
    create_table :partner_affiliations, id: :uuid do |t|
      t.references :donor, foreign_key: true, type: :uuid
      t.references :partner, foreign_key: true, type: :uuid
      t.references :campaign, foreign_key: true, type: :uuid
      t.jsonb :custom_donor_info

      t.timestamps
    end
  end
end
