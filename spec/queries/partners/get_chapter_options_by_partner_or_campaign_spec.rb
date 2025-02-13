require 'rails_helper'

RSpec.describe Partners::GetChapterOptionsByPartnerOrCampaign, type: :query do
  let(:partner) { create(:partner) }
  let(:campaign_partner) { create(:partner) }
  let(:campaign) { create(:campaign, partner: campaign_partner, title: 'Cambridge') }
  let(:other_partner) { create(:partner) }

  before do
    allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
    allow(Partners::GetChapterOptionsByPartner).to receive(:call).with(id: partner.id).and_return(['University of Oxford'])
    allow(Partners::GetChapterOptionsByPartner).to receive(:call).with(id: other_partner.id).and_return(['Other Partner Chapter'])
  end

  describe '#call' do
    subject { described_class.new.call(partner_id:, campaign_id:) }

    context 'when the partner_id is present' do
      let(:partner_id) { partner.id }
      let(:campaign_id) { campaign.id }

      before do
        allow(Partners::GetChapterOptionsByPartner).to receive(:call).with(id: campaign_partner.id).and_return(['University of Cambridge'])
      end

      it 'returns the chapter options for the given partner and campaign' do
        expect(subject).to eq(['University of Cambridge', 'N/A', 'University of Oxford', 'Other (please type in your chapter)'])
      end

      it 'does not return chapter options for other partners' do
        expect(subject).not_to include('Other Partner Chapter')
      end
    end

    context 'when the partner_id is blank' do
      let(:partner_id) { nil }
      let(:campaign_id) { campaign.id }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the campaign_id is blank' do
      let(:partner_id) { partner.id }
      let(:campaign_id) { nil }

      before do
        allow(Partners::GetChapterOptionsByPartner).to receive(:call).with(id: campaign_partner.id).and_return([])
      end

      it 'returns the chapter options for the given partner' do
        expect(subject).to eq(['N/A', 'University of Oxford', 'Other (please type in your chapter)'])
      end
    end

    context 'when the campaign does not exist' do
      let(:partner_id) { partner.id }
      let(:campaign_id) { -1 }

      before do
        allow(Partners::GetChapterOptionsByPartner).to receive(:call).with(id: campaign_partner.id).and_return([])
      end

      it 'returns the chapter options for the given partner' do
        expect(subject).to eq(['N/A', 'University of Oxford', 'Other (please type in your chapter)'])
      end
    end
  end
end
