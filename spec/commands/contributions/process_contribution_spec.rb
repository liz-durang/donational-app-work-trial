# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ProcessContribution do
  include ActiveSupport::Testing::TimeHelpers

  before do |_example|
    allow(Payments::GetActivePaymentMethod)
      .to receive(:call)
      .with(donor:)
      .and_return(payment_method_query_result)
    Partners::AffiliateDonorWithPartner.run(donor:, partner:)
  end

  let!(:partner) do
    # Regardless of whether the payment method is located on the Stripe platform or connected accounts, the Donational
    # partner record always lists the account id as that the connected account.
    create(:partner, :default, payment_processor_account_id: 'acc_123', platform_fee_percentage: 0.03)
  end
  let(:donor) do
    create(:donor, email: 'user@example.com')
  end
  let(:contribution_processed_at) { nil }
  let(:contribution) do
    create(:contribution, donor:, partner:, processed_at: contribution_processed_at)
  end
  let(:payment_method_type) { PaymentMethods::Card }
  let(:payment_method_factory) { :payment_method }
  let(:payment_method_query_result) do
    build(
      payment_method_factory,
      donor:,
      payment_processor_customer_id: 'cus_123',
      payment_processor_source_id: 'pm_123',
      type: payment_method_type
    )
  end

  context 'when the donor has no payment method' do
    let(:payment_method_query_result) { nil }

    it 'does not process any payments' do
      expect(Payments::PlatformAccount::ChargeCustomerUsBankAccount).not_to receive(:run)
      expect(Payments::PlatformAccount::ChargeCustomerCard).not_to receive(:run)
      expect(Payments::ConnectedAccount::ChargeCustomer).not_to receive(:run)

      command = described_class.run(contribution:)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_method: :not_found)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the contribution has already been processed' do
    let(:contribution_processed_at) { 1.day.ago }

    it 'does not process any payments' do
      expect(Payments::PlatformAccount::ChargeCustomerUsBankAccount).not_to receive(:run)
      expect(Payments::PlatformAccount::ChargeCustomerCard).not_to receive(:run)
      expect(Payments::ConnectedAccount::ChargeCustomer).not_to receive(:run)

      command = described_class.run(contribution:)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
      expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
    end
  end

  context 'when the contribution has not been processed and the donor has a payment method' do
    let(:currency) { 'usd' }
    let(:charge_errors) { { some: 'error' } }
    let(:unsuccessful_charge) { double(success?: false, errors: charge_errors) }
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
    let(:portfolio) { create(:portfolio) }

    let(:contribution) do
      create(
        :contribution,
        donor:,
        portfolio:,
        amount_cents: 1_000,
        tips_cents: 200,
        processed_at: nil,
        amount_currency: currency
      )
    end

    let(:org_1) { create(:organization, ein: 'org1') }
    let(:org_2) { create(:organization, ein: 'org2') }
    let(:allocation_1) do
      build(:allocation, portfolio:, organization: org_1, percentage: 60)
    end
    let(:allocation_2) do
      build(:allocation, portfolio:, organization: org_2, percentage: 40)
    end

    let(:successful_outcome) { double(success?: true) }

    before do
      allow(Payments::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor:)
        .and_return(payment_method_query_result)
    end

    around do |spec|
      travel_to(Time.zone.now.change(usec: 0)) do
        spec.run
      end
    end

    context 'and the payment method is located on a platform account' do
      before do
        # Not using StripeMock library because it does not scope records by account.
        # https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/737
        # Also, StripeMock doesn't allow payment method types other than card, ideal, and sepa_debit.
        allow(Stripe::PaymentMethod)
          .to receive(:retrieve)
          .with('pm_123', { stripe_account: 'acc_123' })
          .and_return(nil)
      end

      context 'and the payment method type is card' do
        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::PlatformAccount::ChargeCustomerCard).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(charge_command_class: Payments::PlatformAccount::ChargeCustomerCard)
          end
        end
      end

      context 'and the payment method type is US bank account' do
        let(:payment_method_type) { PaymentMethods::BankAccount }
        let(:payment_method_factory) { :us_bank_account_payment_method }

        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::PlatformAccount::ChargeCustomerUsBankAccount).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(charge_command_class: Payments::PlatformAccount::ChargeCustomerUsBankAccount)
          end
        end
      end
    end

    context 'and the payment method is located on a connected account' do
      before do
        # Not using StripeMock library because it does not scope records by account.
        # https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/737
        # Also, StripeMock doesn't allow payment method types other than card, ideal, and sepa_debit.
        allow(Stripe::PaymentMethod)
          .to receive(:retrieve)
          .with('pm_123', { stripe_account: 'acc_123' })
          .and_return(Stripe::PaymentMethod.new)
      end

      context 'and the payment method type is card' do
        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::ConnectedAccount::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(
              charge_command_class: Payments::ConnectedAccount::ChargeCustomer
            )
          end
        end
      end

      context 'and the payment method type is US bank account' do
        let(:payment_method_type) { PaymentMethods::BankAccount }
        let(:payment_method_factory) { :us_bank_account_payment_method }

        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::ConnectedAccount::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(
              charge_command_class: Payments::ConnectedAccount::ChargeCustomer
            )
          end
        end
      end

      context 'and the payment method type is ACSS direct debit' do
        let(:payment_method_type) { PaymentMethods::AcssDebit }
        let(:payment_method_factory) { :acss_debit_payment_method }

        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::ConnectedAccount::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(
              charge_command_class: Payments::ConnectedAccount::ChargeCustomer
            )
          end
        end
      end

      context 'and the payment method type is BACS direct debit' do
        let(:payment_method_type) { PaymentMethods::BacsDebit }
        let(:payment_method_factory) { :bacs_debit_payment_method }

        context 'and the payment is unsuccessful' do
          before do
            expect(Payments::ConnectedAccount::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
          end

          it 'calls Contributions::ProcessContributionPaymentFailed command' do
            expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
          end
        end

        context 'and the payment is successful' do
          it 'stores the receipt and marks the contribution as processed' do
            expect_successful_charge_with_receipt_and_updated_contribution(
              charge_command_class: Payments::ConnectedAccount::ChargeCustomer
            )
          end
        end
      end
    end
  end

  def expect_payment_failed_command_to_be_run_and_no_updates_to_the_contribution
    expect(Contributions::ProcessContributionPaymentFailed)
      .to receive(:run)
      .with(contribution:, errors: charge_errors.to_json)
      .and_return(successful_outcome)

    command = described_class.run(contribution:)

    expect(command).not_to be_success
    expect(contribution.processed_at).to be_nil
    expect(contribution.platform_fees_cents).to be_nil
    expect(contribution.payment_processor_fees_cents).to be_nil
    expect(contribution.donor_advised_fund_fees_cents).to be_nil
    expect(TriggerContributionProcessedWebhook.jobs.size).to eq(0)
  end

  def expect_successful_charge_with_receipt_and_updated_contribution(charge_command_class:)
    expect(charge_command_class)
      .to receive(:run)
      .with(
        account_id: partner.payment_processor_account_id,
        currency:,
        donation_amount_cents: 1_000,
        metadata:,
        payment_method: payment_method_query_result,
        platform_fee_cents: 30,
        tips_cents: 200
      )
      .and_return(successful_charge)

    command = described_class.run(contribution:)

    expect(command).to be_success
    expect(contribution.receipt).to eq JSON.parse('{ "id": "pi_1IH9IhFfEyMzV1ZsBkMrFF8c", "object": "payment_intent" }')
    expect(contribution.processed_at).to eq Time.zone.now
    expect(contribution.failed_at).to be_nil
    expect(contribution.payment_status).to eq 'pending'
    expect(contribution.payment_processor_account_id).to eq 'acc_123'
    expect(TriggerContributionProcessedWebhook.jobs.size).to eq(1)
  end
end
