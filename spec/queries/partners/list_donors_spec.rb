require 'rails_helper'

RSpec.describe Partners::ListDonors, type: :query do
  let(:partner) { create(:partner) }
  let(:other_partner) { create(:partner) }
  let!(:donor1) { create(:donor, updated_at: 2.days.ago) }
  let!(:donor2) { create(:donor, updated_at: 1.day.ago) }
  let!(:donor3) { create(:donor, deactivated_at: 1.day.ago) }
  let!(:affiliation1) { create(:partner_affiliation, donor: donor1, partner: partner) }
  let!(:affiliation2) { create(:partner_affiliation, donor: donor2, partner: partner) }
  let!(:affiliation3) { create(:partner_affiliation, donor: donor1, partner: other_partner) }

  describe '#call' do
    subject { described_class.new.call(search: search, partner: partner, page: page, per_page: per_page) }

    let(:search) { nil }
    let(:page) { 1 }
    let(:per_page) { 10 }

    context 'when the partner is present' do
      context 'when search is present' do
        let(:search) { donor1.first_name }

        it 'returns the donors matching the search criteria for the given partner' do
          expect(Donor).to receive(:search).with(search, where: { deactivated_at: nil, partner_id: partner.id }, page: page, per_page: per_page).and_return([donor1])
          subject
        end
      end

      context 'when search is not present' do
        it 'returns the donors for the given partner ordered by updated_at descending' do
          expect(subject).to eq([donor2, donor1])
        end

        it 'does not return deactivated donors' do
          expect(subject).not_to include(donor3)
        end
      end
    end

    context 'when the partner is blank' do
      subject { described_class.new.call(search:, partner: nil, page:, per_page:) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
