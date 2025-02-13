require 'rails_helper'

RSpec.describe Partners::GetCampaignBySlug, type: :query do
  let!(:campaign) { create(:campaign, slug: 'test-campaign') }

  describe '#call' do
    subject { described_class.new.call(slug: slug) }

    context 'when the slug is present' do
      let(:slug) { 'test-campaign' }

      it 'returns the campaign with the given slug' do
        expect(subject).to eq(campaign)
      end
    end

    context 'when the slug is blank' do
      let(:slug) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the campaign with the given slug does not exist' do
      let(:slug) { 'nonexistent-slug' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
