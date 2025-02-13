require 'rails_helper'

RSpec.describe Partners::GetCampaignById, type: :query do
  let!(:campaign) { create(:campaign) }

  describe '#call' do
    subject { described_class.new.call(id: campaign_id) }

    context 'when the id is present' do
      let(:campaign_id) { campaign.id }

      it 'returns the campaign with the given id' do
        expect(subject).to eq(campaign)
      end
    end

    context 'when the id is blank' do
      let(:campaign_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the campaign with the given id does not exist' do
      let(:campaign_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
