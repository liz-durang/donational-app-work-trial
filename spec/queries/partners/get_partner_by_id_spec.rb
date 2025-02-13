require 'rails_helper'

RSpec.describe Partners::GetPartnerById, type: :query do
  let!(:partner) { create(:partner) }

  describe '#call' do
    subject { described_class.new.call(id: partner_id) }

    context 'when the id is present' do
      let(:partner_id) { partner.id }

      it 'returns the partner with the given id' do
        expect(subject).to eq(partner)
      end
    end

    context 'when the id is blank' do
      let(:partner_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the partner with the given id does not exist' do
      let(:partner_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
