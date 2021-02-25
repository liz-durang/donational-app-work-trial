# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ProcessContributionPaymentFailed do
  include ActiveSupport::Testing::TimeHelpers

  before do |_example|
    create(:partner, :default, payment_processor_account_id: 'acc_123', platform_fee_percentage: 0.03)
  end

  context 'when the contribution has already been processed' do
    let(:charge_errors) { { some: 'error' }.to_json }
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process payment failed' do
      expect(Payments::IncrementRetryCount).not_to receive(:run)

      command = described_class.run(contribution: contribution, errors: charge_errors)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
      expect(TriggerPaymentFailedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the contribution has not been processed' do
    let(:currency) { 'usd' }
    let(:donor) { create(:donor, email: 'user@example.com') }
    let(:portfolio) { create(:portfolio) }
    let(:subscription) { create(:subscription, donor: donor, deactivated_at: nil) }

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

    let(:payment_method) do
      create(
        :payment_method,
        payment_processor_customer_id: 'cus_123',
        type: PaymentMethods::Card,
        retry_count: 0
      )
    end

    before do
      allow(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor: donor)
        .and_return(payment_method)

      expect(Contributions::GetActiveSubscription)
        .to receive(:call)
        .with(donor: donor)
        .and_return(subscription)
    end

    around do |spec|
      travel_to(Time.zone.now.change(usec: 0)) do
        spec.run
      end
    end

    context 'and the payment is unsuccessful' do
      let(:charge_errors) { { some: 'error' }.to_json }

      it 'marks the contribution as failed and unprocessed' do
        command = described_class.run(contribution: contribution, errors: charge_errors)

        expect(command).to be_success
        expect(contribution.processed_at).to be nil
        expect(contribution.failed_at).to eq Time.zone.now
        expect(contribution.payment_status).to eq 'failed'
        expect(contribution.receipt).to eq JSON.parse(charge_errors)
        expect(TriggerPaymentFailedWebhook.jobs.size).to eq(1)
      end

      it 'increments payment method retry count' do
        command = described_class.run(contribution: contribution, errors: charge_errors)

        expect(command).to be_success
        expect(payment_method.retry_count).to be 1
      end
    end
  end
end
