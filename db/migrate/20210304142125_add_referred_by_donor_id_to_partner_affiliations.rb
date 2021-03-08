class AddReferredByDonorIdToPartnerAffiliations < ActiveRecord::Migration[5.2]
  def change
    add_reference :partner_affiliations, :referred_by_donor, foreign_key: { to_table: :donors }, type: :uuid
  end
end
