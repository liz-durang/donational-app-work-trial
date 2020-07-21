require 'rails_helper'

RSpec.describe Partners::MigrateAffiliationToNewPartner do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner, name: "Old Partner") }
  let(:campaign) { create(:campaign, title: "Campaign") }
  let(:custom_donor_info) { { existing_q: 'existing answer'} }

  context 'when there is a new partner' do
    let(:new_partner) { create(:partner, name: "New Partner") }
    it 'has the same info with the new partner' do
      partner_affiliation = create(:partner_affiliation, donor: donor, partner: partner, campaign: campaign, custom_donor_info: custom_donor_info)
      expect(Partners::GetPartnerForDonor.call(donor: donor).name).to eq "Old Partner"
      Partners::MigrateAffiliationToNewPartner.run(partner_affiliation: partner_affiliation, partner: new_partner)
      expect(Partners::GetPartnerForDonor.call(donor: donor).name).to eq "New Partner"
      expect(Partners::GetPartnerAffiliationByDonor.call(donor: donor).campaign.title).to eq "Campaign"
      expect(Partners::GetPartnerAffiliationByDonor.call(donor: donor).custom_donor_info["existing_q"]).to eq 'existing answer'
    end
  end

end
