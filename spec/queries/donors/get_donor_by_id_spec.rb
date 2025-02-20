require 'rails_helper'

RSpec.describe Donors::GetDonorById, type: :query do
  let!(:donor) { create(:donor) }

  describe '#call' do
    subject { described_class.new.call(id: donor_id) }

    context 'when the id is present' do
      let(:donor_id) { donor.id }

      it 'returns the donor with the given id' do
        expect(subject).to eq(donor)
      end
    end

    context 'when the id is blank' do
      let(:donor_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the donor with the given id does not exist' do
      let(:donor_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
