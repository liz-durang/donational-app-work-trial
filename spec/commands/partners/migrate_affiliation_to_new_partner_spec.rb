# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Partners::MigrateAffiliationToNewPartner do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner, name: 'Old Partner') }
  let(:campaign) { create(:campaign, title: 'Campaign') }
  let(:custom_donor_info) { { existing_q: 'existing answer' } }

  context 'when there is a new partner' do
    let(:new_partner) { create(:partner, name: 'New Partner') }
    let!(:partner_affiliation) do
      create(:partner_affiliation, donor: donor, partner: partner, campaign: campaign, custom_donor_info: custom_donor_info)
    end

    it 'has the same info with the new partner' do
      expect(Partners::GetPartnerForDonor.call(donor: donor).name).to eq 'Old Partner'
      described_class.run(partner_affiliation: partner_affiliation, partner: new_partner)
      expect(Partners::GetPartnerForDonor.call(donor: donor).name).to eq 'New Partner'
      expect(Partners::GetPartnerAffiliationByDonor.call(donor: donor).campaign.title).to eq 'Campaign'
      expect(Partners::GetPartnerAffiliationByDonor.call(donor: donor).custom_donor_info['existing_q']).to eq 'existing answer'
    end

    it 'reindexes the donor' do
      expect(donor).to receive(:reindex).at_least(:once)
      described_class.run(partner_affiliation: partner_affiliation, partner: new_partner)
    end
  end
end
