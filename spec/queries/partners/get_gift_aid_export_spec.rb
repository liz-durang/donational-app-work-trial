require 'rails_helper'

RSpec.describe Partners::GetGiftAidExport, type: :query do
  let(:partner) { create(:partner) }
  let(:donor) { create(:donor, uk_gift_aid_accepted: true, title: 'Mr', first_name: 'John', last_name: 'Doe', house_name_or_number: '123', postcode: 'AB12 3CD') }
  let(:non_gift_aid_donor) { create(:donor, uk_gift_aid_accepted: false) }
  let!(:contribution) { create(:contribution, partner: partner, donor: donor, amount_cents: 1000, created_at: 1.day.ago, payment_status: :succeeded) }
  let(:non_gift_aid_contribution) { create(:contribution, partner: partner, donor: non_gift_aid_donor, amount_cents: 2000, created_at: 1.day.ago, payment_status: :succeeded) }
  let(:failed_contribution) { create(:contribution, partner: partner, donor: donor, amount_cents: 3000, created_at: 1.day.ago, payment_status: :failed) }
  let(:other_partner_contribution) { create(:contribution, donor: donor, amount_cents: 4000, created_at: 1.day.ago, payment_status: :succeeded) }
  let(:donated_between) { 2.days.ago..Time.now }

  describe '#call' do
    subject { described_class.new.call(partner:, donated_between:) }

    context 'when the partner is present' do
      it 'returns the gift aid export data for the given partner and date range' do
        expect(subject.first.title).to eq(donor.title)
        expect(subject.first.first_name).to eq(donor.first_name)
        expect(subject.first.last_name).to eq('Doe')
        expect(subject.first.house_name_or_number).to eq(donor.house_name_or_number)
        expect(subject.first.postcode).to eq(donor.postcode.upcase)
        expect(subject.first.aggregated_donations).to be_nil
        expect(subject.first.sponsored_event).to be_nil
        expect(subject.first.date).to eq(contribution.created_at.strftime('%d/%m/%y'))
        expect(subject.first.amount).to eq('10.00'.to_f)
      end

      it 'does not return contributions from donors who have not accepted gift aid' do
        expect(subject).not_to include(non_gift_aid_contribution)
      end

      it 'does not return failed contributions' do
        expect(subject).not_to include(failed_contribution)
      end

      it 'does not return contributions from other partners' do
        expect(subject).not_to include(other_partner_contribution)
      end
    end

    context 'when partner is blank' do
      subject { described_class.new.call(partner: nil, donated_between: donated_between) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
