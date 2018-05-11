require 'rails_helper'

RSpec.describe Contributions::ProcessContribution do
  include ActiveSupport::Testing::TimeHelpers

  context 'when the donor has no payment method' do
    let(:contribution) { create(:contribution, processed_at: nil) }

    before do
      expect(PaymentMethods::GetActivePaymentMethod)
        .to receive(:call)
        .and_return(nil)
    end

    it 'does not process any payments' do
      expect(Payments::ChargeCustomer).not_to receive(:run)

      command = Contributions::ProcessContribution.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_method: :not_found)
    end
  end

  context 'when the Contribution has already been processed' do
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Payments::ChargeCustomer).not_to receive(:run)

      command = Contributions::ProcessContribution.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
    end
  end

  context 'when the Contribution has not been processed and the donor has a payment method' do
    let(:donor) do
      create(:donor, email: 'user@example.com')
    end

    let(:payment_method_query_result) { double(customer_id: 'cus_123') }

    let(:portfolio) { create(:portfolio, donor: donor) }
    let(:contribution) do
      create(:contribution, donor: donor, portfolio: portfolio, amount_cents: 1_000, platform_fee_cents: 200, processed_at: nil)
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
      expect(PaymentMethods::GetActivePaymentMethod)
        .to receive(:call)
        .with(donor: donor)
        .and_return(payment_method_query_result)

      allow(Allocations::GetActiveAllocations)
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
      let(:charge_errors) { double(to_json: 'errors_as_json') }
      let(:unsuccessful_charge) { double(success?: false, errors: charge_errors) }

      before do
        expect(Payments::ChargeCustomer).to receive(:run).and_return(unsuccessful_charge)
      end

      it 'marks the contribution as failed and unprocessed' do
        command = Contributions::ProcessContribution.run(contribution: contribution)

        expect(command).not_to be_success

        expect(contribution.processed_at).to be nil
        expect(contribution.failed_at).to eq Time.zone.now
        expect(contribution.receipt).to eq 'errors_as_json'
      end

      it 'does not track an analytics event' do
        expect(Analytics::TrackEvent).not_to receive(:run)
        command = Contributions::ProcessContribution.run(contribution: contribution)
      end
    end

    context 'and the payment is successful' do
      let(:successful_charge) do
        double(success?: true, result: '{ "some": "receipt" }')
      end

      let(:successful_track_event) { double(success?: true) }
      it 'stores the receipt and marks the contribution as processed' do
        expect(Payments::ChargeCustomer)
          .to receive(:run)
          .with(email: 'user@example.com', customer_id: 'cus_123', donation_amount_cents: 1_000, platform_fee_cents: 200)
          .and_return(successful_charge)
        expect(Analytics::TrackEvent).to receive(:run).and_return(successful_track_event)

        command = Contributions::ProcessContribution.run(contribution: contribution)

        expect(command).to be_success

        contribution.reload
        expect(contribution.receipt).to eq '{ "some": "receipt" }'
        expect(contribution.processed_at).to eq Time.zone.now
        expect(contribution.failed_at).to be nil
      end

      it "creates donations based on the donor's allocations" do
        allow(Payments::ChargeCustomer).to receive(:run).and_return(successful_charge)
        expect(Analytics::TrackEvent).to receive(:run).and_return(successful_track_event)

        expect { Contributions::ProcessContribution.run(contribution: contribution) }.to change { Donation.count }.by(2)

        expect(Donation.where(organization: org_1).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 553)
        expect(Donation.where(organization: org_2).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 369)
      end
    end
  end
end
