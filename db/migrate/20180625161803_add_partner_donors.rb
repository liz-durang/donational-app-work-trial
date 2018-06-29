class AddPartnerDonors < ActiveRecord::Migration[5.1]
  def change
    create_table :donors_partners, id: false do |t|
      t.belongs_to :donor, index: true, type: :uuid
      t.belongs_to :partner, index: true, type: :uuid
    end
  end
end
