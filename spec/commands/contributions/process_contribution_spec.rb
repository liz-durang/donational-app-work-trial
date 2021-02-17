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
      expect(Payments::ChargeCustomerBankAccount).not_to receive(:run)
      expect(Payments::ChargeCustomerCard).not_to receive(:run)

      command = described_class.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_method: :not_found)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the contribution has already been processed' do
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Payments::ChargeCustomerBankAccount).not_to receive(:run)
      expect(Payments::ChargeCustomerCard).not_to receive(:run)

      command = described_class.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the contribution has not been processed and the donor has a payment method' do
    let(:donor) do
      create(:donor, email: 'user@example.com')
    end

    let(:currency) { 'usd' }
    let(:portfolio) { create(:portfolio) }

    let(:contribution) do
      create(
        :contribution,
        donor: donor,
        portfolio: portfolio,
        amount_cents: 1_000,
        tips_cents: 200,
        processed_at: nil,
        amount_currency: currency
      )
    end

    let(:payment_method_query_result) do
      build(
        :payment_method,
        payment_processor_customer_id: 'cus_123',
        payment_processor_source_id: 'pm_123',
        type: PaymentMethods::Card
      )
    end

    let(:org_1) { create(:organization, ein: 'org1') }
    let(:org_2) { create(:organization, ein: 'org2') }
    let(:allocation_1) do
      build(:allocation, portfolio: portfolio, organization: org_1, percentage: 60)
    end
    let(:allocation_2) do
      build(:allocation, portfolio: portfolio, organization: org_2, percentage: 40)
    end

    let(:successful_outcome) { double(success?: true) }

    before do
      allow(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor: donor)
        .and_return(payment_method_query_result)
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
        expect(Payments::ChargeCustomerCard).to receive(:run).and_return(unsuccessful_charge)
      end

      it 'calls Contributions::ProcessContributionPaymentFailed command' do
        expect(Contributions::ProcessContributionPaymentFailed)
          .to receive(:run)
          .with(contribution: contribution, errors: charge_errors.to_json)
          .and_return(successful_outcome)

        command = described_class.run(contribution: contribution)

        expect(command).not_to be_success
        expect(contribution.processed_at).to be nil
        expect(contribution.platform_fees_cents).to be nil
        expect(contribution.payment_processor_fees_cents).to be nil
        expect(contribution.donor_advised_fund_fees_cents).to be nil
        expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
      end
    end

    context 'and the payment is successful' do
      let(:successful_track_event) { double(success?: true) }
      let(:successful_charge) do
        double(
          success?: true,
          result: OpenStruct.new(
            payment_processor_fees_cents: 56,
            receipt: JSON.parse('{ "id": "pi_1IH9IhFfEyMzV1ZsBkMrFF8c", "object": "payment_intent" }')
          )
        )
      end
      let(:metadata) do
        {
          donor_id: contribution.donor.id,
          portfolio_id: contribution.portfolio.id,
          contribution_id: contribution.id
        }
      end

      it 'stores the receipt and marks the contribution as processed' do
        expect(Payments::ChargeCustomerCard)
          .to receive(:run)
          .with(
            account_id: 'acc_123',
            currency: currency,
            donation_amount_cents: 1_000,
            metadata: metadata,
            payment_method: payment_method_query_result,
            platform_fee_cents: 30,
            tips_cents: 200
          )
          .and_return(successful_charge)

        command = described_class.run(contribution: contribution)

        expect(command).to be_success
        expect(contribution.receipt).to eq JSON.parse('{ "id": "pi_1IH9IhFfEyMzV1ZsBkMrFF8c", "object": "payment_intent" }')
        expect(contribution.processed_at).to eq Time.zone.now
        expect(contribution.failed_at).to be nil
        expect(contribution.payment_status).to eq 'pending'
        expect(contribution.payment_processor_account_id).to eq 'acc_123'
        expect(TriggerContributionProcessedWebhook.jobs.size).to eq(1)
      end
    end
  end
end
