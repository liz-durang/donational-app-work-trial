require 'rails_helper'

RSpec.describe Partners::GetPartnerAffiliationByDonorAndPartner, type: :query do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let!(:partner_affiliation) { create(:partner_affiliation, donor: donor, partner: partner) }
  let!(:other_affiliation) { create(:partner_affiliation) }

  describe '#call' do
    subject { described_class.new.call(donor: donor, partner: partner) }

    context 'when the donor and partner are present' do
      it 'returns the partner affiliation for the given donor and partner' do
        expect(subject).to eq(partner_affiliation)
      end
    end

    context 'when the donor is blank' do
      subject { described_class.new.call(donor: nil, partner:) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the partner is blank' do
      subject { described_class.new.call(donor:, partner: nil) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the partner affiliation does not exist' do
      let!(:partner_affiliation) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
