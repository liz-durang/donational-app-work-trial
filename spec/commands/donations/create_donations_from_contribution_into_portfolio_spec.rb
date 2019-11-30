require 'rails_helper'

RSpec.describe Donations::CreateDonationsFromContributionIntoPortfolio do
  context 'when the Contribution has been processed' do
    let(:donor) { create(:donor, email: 'user@example.com') }
    let(:operating_costs_org) { create(:organization, ein: 'org_ops_costs') }
    let(:partner) { create(:partner, operating_costs_organization: operating_costs_org) }
    let(:portfolio) { create(:portfolio) }
    let(:contribution) do
      create(:contribution, donor: donor, partner: partner, portfolio: portfolio, amount_cents: 1_000, tips_cents: 200, partner_contribution_percentage: 0)
    end
    let(:another_contribution) do
      create(:contribution, donor: donor, partner: partner, portfolio: portfolio, amount_cents: 1_000, tips_cents: 200, partner_contribution_percentage: 10)
    end
    let(:org_1) { create(:organization, ein: 'org_1') }
    let(:org_2) { create(:organization, ein: 'org_2') }
    let(:allocation_1) { build(:allocation, portfolio: portfolio, organization: org_1, percentage: 60) }
    let(:allocation_2) { build(:allocation, portfolio: portfolio, organization: org_2, percentage: 40) }

    before do
      allow(Portfolios::GetActiveAllocations)
        .to receive(:call)
        .with(portfolio: portfolio)
        .and_return([allocation_1, allocation_2])
    end

    context 'and the partner contribution percentage is 0' do
      it "creates donations based on the donor's allocations" do

        expect { Donations::CreateDonationsFromContributionIntoPortfolio.run(contribution: contribution, donation_amount_cents: 934) }.to change { Donation.count }.by(2)

        # (934 after fees) * 0.6
        expect(Donation.where(organization: org_1).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 560)

        # (934 after fees) * 0.4
        expect(Donation.where(organization: org_2).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 373)
      end
    end

    context 'and the partner contribution percentage is 10' do
      it "creates donations based on the donor's allocations and creates a donation to the partner to cover operating costs" do
        expect { Donations::CreateDonationsFromContributionIntoPortfolio.run(contribution: another_contribution, donation_amount_cents: 934) }.to change { Donation.count }.by(3)

        # 934 * 10% to operating costs = 93
        expect(Donation.where(organization: operating_costs_org).first)
          .to have_attributes(contribution: another_contribution, amount_cents: 93)

        # (934 - 93) * 60%
        expect(Donation.where(organization: org_1).first)
          .to have_attributes(contribution: another_contribution, portfolio_id: portfolio.id, amount_cents: 504)

        # (934 - 93) * 40%
        expect(Donation.where(organization: org_2).first)
          .to have_attributes(contribution: another_contribution, portfolio_id: portfolio.id, amount_cents: 336)
      end
    end
  end
end
