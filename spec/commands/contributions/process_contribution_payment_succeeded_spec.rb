# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ProcessContributionPaymentSucceeded do
  include ActiveSupport::Testing::TimeHelpers

  before do |_example|
    create(:partner, :default, payment_processor_account_id: 'acc_123', platform_fee_percentage: 0.03)
  end

  context 'when the contribution payment is successful' do
    let(:donor) { create(:donor, email: 'user@example.com') }
    let(:currency) { 'usd' }
    let(:portfolio) { create(:portfolio) }

    let(:contribution) do
      create(
        :contribution,
        donor: donor,
        portfolio: portfolio,
        amount_cents: 1_000,
        tips_cents: 200,
        processed_at: 1.day.ago,
        amount_currency: currency,
        platform_fees_cents: (0.03 * 1_000),
        payment_processor_fees_cents: 56,
        donor_advised_fund_fees_cents: (0.01 * 1_000),
        amount_donated_after_fees_cents: amount_donated_after_fees_cents
      )
    end

    let(:org_1) { create(:organization, ein: 'org1') }
    let(:org_2) { create(:organization, ein: 'org2') }
    let(:allocation_1) { build(:allocation, portfolio: portfolio, organization: org_1, percentage: 60) }
    let(:allocation_2) { build(:allocation, portfolio: portfolio, organization: org_2, percentage: 40) }

    let(:successful_track_event) { double(success?: true) }
    let(:amount_donated_after_fees_cents) { 1_000 - 56 - (0.01 * 1_000) - (0.03 * 1_000) }
    let(:payment_fees) { OpenStruct.new(amount_donated_after_fees_cents: amount_donated_after_fees_cents) }
    let(:payment_method) { build(:payment_method, payment_processor_customer_id: 'cus_123', type: PaymentMethods::Card) }
    let(:receipt) { { id: 'py_test_1' }.to_json }

    before do
      expect(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor: donor)
        .and_return(payment_method)

      allow(Portfolios::GetActiveAllocations)
        .to receive(:call)
        .with(portfolio: portfolio)
        .and_return([allocation_1, allocation_2])
    end

    around do |spec|
      travel_to(Time.zone.now.change(usec: 0)) do
        spec.run
      end
    end

    it 'updates contribution payment status and receipt' do
      command = described_class.run(contribution: contribution, receipt: receipt)

      expect(command).to be_success
      expect(contribution.payment_status).to eq 'succeeded'
      expect(contribution.failed_at).to be nil
      expect(contribution.receipt).to eq JSON.parse(receipt)
    end

    it "creates donations based on the donor's allocations" do
      expect(Donations::CreateDonationsFromContributionIntoPortfolio)
        .to receive(:run)
        .with(
          contribution: contribution,
          donation_amount_cents: amount_donated_after_fees_cents
        ).and_return(double(success?: true))

      command = described_class.run(contribution: contribution, receipt: receipt)

      expect(command).to be_success
    end

    it 'tracks contribution processed event' do
      expect(Analytics::TrackEvent).to receive(:run).and_return(successful_track_event)

      command = described_class.run(contribution: contribution, receipt: receipt)

      expect(command).to be_success
    end
  end
end
