require 'rails_helper'

RSpec.describe Partners::GetPartnerAffiliationByDonor, type: :query do
  let(:donor) { create(:donor) }
  let!(:partner_affiliation1) { create(:partner_affiliation, donor: donor, created_at: 2.days.ago) }
  let!(:partner_affiliation2) { create(:partner_affiliation, donor: donor, created_at: 1.day.ago) }
  let!(:other_affiliation) { create(:partner_affiliation) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    context 'when the donor is present' do
      it 'returns the most recent partner affiliation for the given donor' do
        expect(subject).to eq(partner_affiliation2)
      end
    end

    context 'when the donor is blank' do
      subject { described_class.new.call(donor: nil) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the donor has no partner affiliations' do
      let!(:partner_affiliation1) { nil }
      let!(:partner_affiliation2) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
