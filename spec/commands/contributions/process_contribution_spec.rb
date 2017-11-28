require 'rails_helper'

RSpec.describe Contributions::ProcessContribution do
  include ActiveSupport::Testing::TimeHelpers

  context 'when the Contribution has already been processed' do
    let(:contribution) { create(:contribution, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Payments::ChargeCustomer).not_to receive(:run)

      command = Contributions::ProcessContribution.run(contribution: contribution)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(contribution: :already_processed)
    end
  end

  context 'when the Contribution has not been processed' do
    let(:donor) do
      create(:donor, email: 'user@example.com', payment_processor_customer_id: 'cus_123')
    end

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

    context 'and the payment is unsuccessful' do
      let(:unsuccessful_widthdrawal) { double(success?: false) }

      it 'leaves the contribution as unprocessed' do
        expect(Payments::ChargeCustomer).to receive(:run).and_return(unsuccessful_widthdrawal)

        command = Contributions::ProcessContribution.run(contribution: contribution)

        expect(command).not_to be_success

        expect(contribution.processed_at).to be nil
      end
    end

    context 'and the payment is successful' do
      let(:successful_widthdrawal) do
        double(success?: true, result: '{ "some": "receipt" }')
      end
      it 'stores the receipt and marks the contribution as processed' do
        expect(Payments::ChargeCustomer)
          .to receive(:run)
          .with(email: 'user@example.com', customer_id: 'cus_123', amount_cents: 123)
          .and_return(successful_widthdrawal)

        command = Contributions::ProcessContribution.run(contribution: contribution)

        expect(command).to be_success

        contribution.reload
        expect(contribution.receipt).to eq '{ "some": "receipt" }'
        expect(contribution.processed_at).to eq Time.zone.now.change(usec: 0)
      end

      it "creates donations based on the donor's allocations" do
        allow(Payments::ChargeCustomer).to receive(:run).and_return(successful_widthdrawal)

        expect { Contributions::ProcessContribution.run(contribution: contribution) }.to change { Donation.count }.by(2)

        expect(Donation.where(organization: org_1).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 73)
        expect(Donation.where(organization: org_2).first)
          .to have_attributes(contribution: contribution, portfolio_id: portfolio.id, amount_cents: 49)
      end
    end
  end
end
