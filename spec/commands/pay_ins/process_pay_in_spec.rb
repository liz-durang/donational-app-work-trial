require 'rails_helper'

RSpec.describe PayIns::ProcessPayIn do
  let(:fake_payment_processor) do
    double(:fake_payment_processor)
  end

  context 'when the PayIn has already been processed' do
    let(:pay_in) { create(:pay_in, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(fake_payment_processor).not_to receive(:withdraw_from_donor!)

      outcome = PayIns::ProcessPayIn.run(pay_in: pay_in, payment_processor: fake_payment_processor)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(pay_in: :already_processed)
    end
  end

  context 'when the PayIn has not been processed' do
    let(:donor) { create(:donor) }
    let(:subscription) { create(:subscription, donor: donor) }
    let(:pay_in) do
      create(:pay_in, subscription: subscription, amount_cents: 123, processed_at: nil)
    end
    let(:org_1) { create(:organization, ein: 'org1') }
    let(:org_2) { create(:organization, ein: 'org2') }
    let(:allocation_1) do
      build(:allocation, subscription: subscription, organization: org_1, percentage: 60)
    end
    let(:allocation_2) do
      build(:allocation, subscription: subscription, organization: org_2, percentage: 40)
    end

    before do
      allow(Allocations::GetActiveAllocations)
        .to receive(:call)
        .with(subscription: subscription)
        .and_return([allocation_1, allocation_2])
    end

    around do |spec|
      Timecop.freeze { spec.run }
    end

    it "withdraws the pay in amount from the donor's account" do
      payment_receipt_json = '{ "some": "receipt" }'

      expect(fake_payment_processor)
        .to receive(:withdraw_from_donor!)
        .with(donor: donor, amount_cents: 123)
        .and_return(payment_receipt_json)

      outcome = PayIns::ProcessPayIn.run(pay_in: pay_in, payment_processor: fake_payment_processor)

      expect(outcome).to be_success

      pay_in.reload
      expect(pay_in.receipt).to eq payment_receipt_json
      expect(pay_in.processed_at).to eq Time.zone.now
    end

    it "creates donations based on the donor's allocations" do
      allow(fake_payment_processor).to receive(:withdraw_from_donor!)

      expect {
        PayIns::ProcessPayIn.run(pay_in: pay_in, payment_processor: fake_payment_processor)
      }.to change { Donation.count }.by(2)

      expect(Donation.where(organization: org_1).first)
        .to have_attributes(pay_in: pay_in, subscription_id: subscription.id, amount_cents: 73)
      expect(Donation.where(organization: org_2).first)
        .to have_attributes(pay_in: pay_in, subscription_id: subscription.id, amount_cents: 49)
    end
  end
end
