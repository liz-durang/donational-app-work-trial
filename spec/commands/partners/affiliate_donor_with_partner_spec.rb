require 'rails_helper'

RSpec.describe Partners::AffiliateDonorWithPartner do
  subject do
    Partners::AffiliateDonorWithPartner.run(donor: donor, partner: partner, campaign: campaign)
  end

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:campaign) { create(:campaign) }

  context 'when the donor is not affiliated with a partner and has never made a contribution' do
    it 'affiliates the donor with the partner' do
      expect { subject }.to change { PartnerAffiliation.count }.from(0).to(1)

      expect(Partners::GetPartnerForDonor.call(donor: donor)).to eq partner
    end
  end

  context 'when the donor is already affiliated with a partner' do
    let(:other_partner) { create(:partner) }

    let!(:existing_affiliation) do
      create(:partner_affiliation, donor: donor, partner: other_partner)
    end

    it 'does not change the affiliation' do
      expect { subject }.not_to(change { PartnerAffiliation.count })

      expect(Partners::GetPartnerForDonor.call(donor: donor)).to eq other_partner
    end
  end

  context 'when the donor is unaffiliated but has already made a contribution' do
    before do
      expect(Contributions::HasPreviousOrUpcomingContribution).to receive(:call).and_return(true)
    end

    it 'does not change the affiliation' do
      expect { subject }.not_to(change { PartnerAffiliation.count })

      expect(Partners::GetPartnerForDonor.call(donor: donor)).to eq nil
    end
  end

end
