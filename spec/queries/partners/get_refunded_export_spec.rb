require 'rails_helper'

RSpec.describe Partners::GetRefundedExport, type: :query do
  let(:partner) { create(:partner) }
  let(:organization) { create(:organization) }
  let(:managed_portfolio) { create(:managed_portfolio) }
  let(:portfolio) { create(:portfolio, managed_portfolio: managed_portfolio) }
  let(:donor) { create(:donor) }
  let(:contribution) { create(:contribution, partner: partner, donor: donor, portfolio: portfolio, amount_cents: 100, platform_fees_cents: 100, payment_processor_fees_cents: 100, donor_advised_fund_fees_cents: 100) }
  let!(:donation) { create(:donation, contribution: contribution, organization: organization, created_at: 1.day.ago, amount_cents: 100, refunded_at: 1.day.ago) }
  let(:donated_between) { 2.days.ago..Time.now }

  describe '#call' do
    subject { described_class.new.call(partner: partner, donated_between: donated_between) }

    context 'when the partner is present' do
      it 'returns the donations export data for the given partner and date range' do
        expect(subject.first.donor_id).to eq(donor.id)
        expect(subject.first.first_name).to eq(donor.first_name)
        expect(subject.first.last_name).to eq(donor.last_name)
        expect(subject.first.email).to eq(donor.email)
        expect(subject.first.contribution_id).to eq(contribution.id)
        expect(subject.first.contribution_amount).to eq('%.2f' % (contribution.amount_cents / 100.0))
        expect(subject.first.currency).to eq(contribution.amount_currency)
        expect(subject.first.payment_processor_fees).to eq('%.2f' % (contribution.payment_processor_fees_cents / 100.0))
        expect(subject.first.platform_fees).to eq('%.2f' % (contribution.platform_fees_cents / 100.0))
        expect(subject.first.donor_advised_fund_fees).to eq('%.2f' % (contribution.donor_advised_fund_fees_cents / 100.0))
        expect(subject.first.donation_id).to eq(donation.id)
        expect(subject.first.donation_amount).to eq('%.2f' % (donation.amount_cents / 100.0))
        expect(subject.first.organization_ein).to eq(organization.ein)
        expect(subject.first.organization_name).to eq(organization.name)
        expect(subject.first.portfolio_name).to eq('Custom Portfolio')
      end
    end
  end
end
