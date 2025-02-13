require 'rails_helper'

RSpec.describe Partners::GetOrganizationsExport, type: :query do
  let(:partner) { create(:partner, currency: 'USD') }
  let(:organization1) { create(:organization, ein: '123456789', name: 'Organization 1') }
  let(:organization2) { create(:organization, ein: '987654321', name: 'Organization 2') }
  let(:donor1) { create(:donor) }
  let(:donor2) { create(:donor) }
  let(:contribution1) { create(:contribution, partner: partner, donor: donor1) }
  let(:contribution2) { create(:contribution, partner: partner, donor: donor2) }
  let!(:donation1) { create(:donation, contribution: contribution1, organization: organization1, amount_cents: 1000, created_at: 1.day.ago) }
  let!(:donation2) { create(:donation, contribution: contribution2, organization: organization1, amount_cents: 2000, created_at: 1.day.ago) }
  let!(:donation3) { create(:donation, contribution: contribution1, organization: organization2, amount_cents: 3000, created_at: 1.day.ago) }
  let(:donated_between) { 2.days.ago..Time.now }

  describe '#call' do
    subject { described_class.new.call(partner:, donated_between:) }

    context 'when the partner is present' do
      it 'returns the organizations export data for the given partner and date range' do
        expect(subject[0].organization_ein).to eq('123456789')
        expect(subject[0].total_donations_amount_usd).to eq('30.00'.to_f)
        expect(subject[0].total_contributions).to eq(2)
        expect(subject[0].unique_donors).to eq(2)
        expect(subject[0].organization_name).to eq('Organization 1')

        expect(subject[1].organization_ein).to eq('987654321')
        expect(subject[1].total_donations_amount_usd).to eq('30.00'.to_f)
        expect(subject[1].total_contributions).to eq(1)
        expect(subject[1].unique_donors).to eq(1)
        expect(subject[1].organization_name).to eq('Organization 2')
      end
    end

    context 'when the partner is blank' do
      subject { described_class.new.call(partner: nil, donated_between:) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
