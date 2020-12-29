# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ProcessContribution do
  include ActiveSupport::Testing::TimeHelpers

  before do |_example|
    create(:partner, :default, payment_processor_account_id: 'acc_123', platform_fee_percentage: 0.03)
  end

  context 'when the donor has no payment method' do
    let(:contribution) { create(:contribution, processed_at: nil) }

    before do
      expect(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .and_return(nil)
    end

    it 'does not process any payments' do
      expect(Payments::ChargeCustomer).not_to receive(:run)

      command = described_class.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_method: :not_found)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the Contribution has already been processed' do
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Payments::ChargeCustomer).not_to receive(:run)

      command = described_class.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the Contribution has not been processed and the donor has a payment method' do
    let(:donor) do
      create(:donor, email: 'user@example.com')
    end

    let(:payment_method_query_result) { build(:payment_method, payment_processor_customer_id: 'cus_123') }

    let(:portfolio) { create(:portfolio) }
    let(:currency) { 'usd' }
    let(:contribution) do
      create(:contribution, donor: donor, portfolio: portfolio,
                            amount_cents: 1_000, tips_cents: 200, processed_at: nil, amount_currency: currency)
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
      expect(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor: donor)
        .and_return(payment_method_query_result)

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

    context 'and the payment is unsuccessful' do
      let(:charge_errors) { { some: 'error' } }
      let(:unsuccessful_charge) { double(success?: false, errors: charge_errors) }

      before do
        expect(Payments::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
      end

      it 'marks the contribution as failed and unprocessed' do
        command = described_class.run(contribution: contribution)

        expect(command).not_to be_success

        expect(contribution.processed_at).to be nil
        expect(contribution.failed_at).to eq Time.zone.now
        expect(contribution.receipt).to eq '{"some":"error"}'
        expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
      end

      it 'does not create donations' do
        expect(Donations::CreateDonationsFromContributionIntoPortfolio).not_to receive(:run)
        command = described_class.run(contribution: contribution)
      end

      it 'does not track an analytics event' do
        expect(Analytics::TrackEvent).not_to receive(:run)
        command = described_class.run(contribution: contribution)
        expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
      end
    end

    context 'and the payment is successful' do
      let(:successful_charge) do
        double(success?: true, result: JSON.parse('{"balance_transaction": { "fee_details":[{"amount":56, "description":"Stripe processing fees", "type":"stripe_fee"}]}}'))
      end

      let(:successful_track_event) { double(success?: true) }
      let(:metadata) do
        {
          donor_id: contribution.donor.id,
          portfolio_id: contribution.portfolio.id,
          contribution_id: contribution.id
        }
      end

      it 'stores the receipt and marks the contribution as processed' do
        expect(Payments::ChargeCustomer)
          .to receive(:run)
          .with(
            email: 'user@example.com',
            customer_id: 'cus_123',
            account_id: 'acc_123',
            donation_amount_cents: 1_000,
            platform_fee_cents: 30,
            tips_cents: 200,
            metadata: metadata,
            currency: currency
          )
          .and_return(successful_charge)
        expect(Analytics::TrackEvent).to receive(:run).and_return(successful_track_event)

        command = described_class.run(contribution: contribution)

        expect(command).to be_success

        contribution.reload
        expect(contribution.receipt).to eq JSON.parse('{"balance_transaction": { "fee_details":[{"amount":56, "description":"Stripe processing fees", "type":"stripe_fee"}]}}')
        expect(contribution.processed_at).to eq Time.zone.now
        expect(contribution.failed_at).to be nil
        expect(contribution.payment_processor_account_id).to eq 'acc_123'
        expect(TriggerContributionProcessedWebhook.jobs.size).to eq(1)
      end

      it "creates donations based on the donor's allocations" do
        expect(Payments::ChargeCustomer).to receive(:run).and_return(successful_charge)
        expect(Donations::CreateDonationsFromContributionIntoPortfolio)
          .to receive(:run)
          .with(
            contribution: contribution,
            donation_amount_cents: 1_000 - 56 - (0.01 * 1_000) - (0.03 * 1_000)
          ).and_return(double(success?: true))

        command = described_class.run(contribution: contribution)
      end
    end
  end
end
