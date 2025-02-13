require 'rails_helper'

RSpec.describe Partners::GetDonorExport, type: :query do
  let(:partner) { create(:partner) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:managed_portfolio) { create(:managed_portfolio) }
  let(:portfolio) { create(:portfolio, managed_portfolio: managed_portfolio) }
  let(:donor) { create(:donor) }
  let!(:partner_affiliation) { create(:partner_affiliation, partner: partner, donor: donor, campaign: campaign) }
  let!(:subscription) { create(:subscription, donor: donor, portfolio: portfolio, amount_cents: 1000, frequency: 'monthly') }
  let!(:payment_method) { create(:payment_method, donor: donor, type: 'PaymentMethods::Card') }

  describe '#call' do
    subject { described_class.new.call(partner: partner) }

    context 'when the partner is present' do
      it 'returns the donor export data for the given partner' do
        expect(subject.first.donor_id).to eq(donor.id)
        expect(subject.first.subscription_id).to eq(subscription.id)
        expect(subject.first.first_name).to eq(donor.first_name)
        expect(subject.first.last_name).to eq(donor.last_name)
        expect(subject.first.email).to eq(donor.email)
        expect(subject.first.partner).to eq(partner.name)
        expect(subject.first.campaign).to eq(campaign.title)
        expect(subject.first.current_portfolio).to eq(managed_portfolio.name)
        expect(subject.first.frequency).to eq(subscription.frequency)
        expect(subject.first.contribution_amount).to eq('%.2f' % (subscription.amount_cents / 100.0))
        expect(subject.first.partner_contribution_percentage).to eq(subscription.partner_contribution_percentage)
        expect(subject.first.payment_method).to eq('Card')
      end
    end
  end
end
