# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ProcessContributionAcssPaymentSucceeded do
  include ActiveSupport::Testing::TimeHelpers

  before do |_example|
    create(:partner, :default, payment_processor_account_id: 'acc_123', platform_fee_percentage: 0.03)

    outcome = Mutations::Outcome.new(true, nil, [], nil)
    allow(Contributions::ProcessContributionPaymentSucceeded).to receive(:run).and_return(outcome)

    StripeMock.start
  end
  after { StripeMock.stop }

  context 'when the charge is successful' do
    let(:donor) { create(:donor, email: 'user@example.com') }
    let(:currency) { 'cad' }
    let(:stripe_account) { 'acc_123' }
    let(:portfolio) { create(:portfolio) }

    let(:contribution) do
      create(
        :contribution,
        donor: donor,
        portfolio: portfolio,
        amount_cents: 1_000,
        processed_at: 1.day.ago,
        amount_currency: currency
      )
    end

    let(:org_1) { create(:organization, ein: 'org1') }
    let(:allocation_1) { build(:allocation, portfolio: portfolio, organization: org_1, percentage: 60) }
    let(:payment_method) { build(:payment_method, :acss_debit, payment_processor_customer_id: 'cus_123') }
    let(:charge) do
      customer = Stripe::Customer.create({}, stripe_account: stripe_account)
      Stripe::Charge.create(
        {
          customer: customer,
          amount: contribution.amount_cents,
          currency: contribution.amount_currency,
          metadata: { contribution_id: contribution.id }
        },
        stripe_account: stripe_account
      )
    end

    around do |spec|
      travel_to(Time.zone.now.change(usec: 0)) do
        spec.run
      end
    end

    it 'updates contribution fees' do
      expect { described_class.run(charge: charge, account_id: stripe_account) }
        .to change { contribution.reload.payment_processor_fees_cents }
    end

    it "calls regular payment suceedeed handler" do
      expect(Contributions::ProcessContributionPaymentSucceeded)
        .to receive(:run)
        .with(contribution: contribution, receipt: charge.to_json)

      command = described_class.run(charge: charge, account_id: stripe_account)

      expect(command).to be_success
    end
  end
end
