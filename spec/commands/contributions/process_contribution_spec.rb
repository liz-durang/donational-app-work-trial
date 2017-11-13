require 'rails_helper'

RSpec.describe Contributions::ProcessContribution do
  include ActiveSupport::Testing::TimeHelpers

  context 'when the Contribution has already been processed' do
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Withdrawals::WithdrawFromDonor).not_to receive(:run)

      outcome = Contributions::ProcessContribution.run(contribution: contribution)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(contribution: :already_processed)
    end
  end

  context 'when the Contribution has not been processed' do
    let(:donor) { create(:donor) }
    let(:portfolio) { create(:portfolio, donor: donor) }
    let(:contribution) do
      create(:contribution, portfolio: portfolio, amount_cents: 123, processed_at: nil)
    end
    let(:org_1) { create(:organization, ein: 'org1') }
    let(:org_2) { create(:organization, ein: 'org2') }
    let(:allocation_1) do
      build(:allocation, portfolio: portfolio, organization: org_1, percentage: 60)
    end
    let(:allocation_2) do
      build(:allocation, portfolio: portfolio, organization: org_2, percentage: 40)
    end

    before do
      allow(Allocations::GetActiveAllocations)
        .to receive(:call)
        .with(portfolio: portfolio)
        .and_return([allocation_1, allocation_2])
    end

    around do |spec|
      travel_to(Time.now) do
        spec.run
      end
    end

    it "withdraws the pay in amount from the donor's account" do
      payment_receipt_json = '{ "some": "receipt" }'

      expect(Withdrawals::WithdrawFromDonor)
        .to receive(:run)
        .with(donor: donor, amount_cents: 123)
        .and_return(payment_receipt_json)

      outcome = Contributions::ProcessContribution.run(contribution: contribution)

      expect(outcome).to be_success

      contribution.reload
      expect(contribution.receipt).to eq payment_receipt_json
      expect(contribution.processed_at).to eq Time.zone.now.change(usec: 0)
    end

    it "creates donations based on the donor's allocations" do
      allow(Withdrawals::WithdrawFromDonor).to receive(:run)

      expect { Contributions::ProcessContribution.run(contribution: contribution) }.to change { Donation.count }.by(2)

      expect(Donation.where(organization: org_1).first)
        .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 73)
      expect(Donation.where(organization: org_2).first)
        .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 49)
    end
  end
end
