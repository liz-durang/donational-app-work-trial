require 'rails_helper'

RSpec.describe PayOuts::ProcessPayOut do
  context 'when the PayOut has already been processed' do
    let(:pay_out) { create(:pay_out, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Checks::SendCheck).not_to receive(:run)

      outcome = PayOuts::ProcessPayOut.run(pay_out: pay_out)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(pay_out: :already_processed)
    end
  end

  context 'when the PayOut has not been processed' do
    let(:organization) { create(:organization) }
    let(:pay_out) do
      create(:pay_out, organization: organization, amount_cents: 123, processed_at: nil)
    end

    around do |spec|
      Timecop.freeze { spec.run }
    end

    it "sends a check to the organization and persists the processed at time" do
      expect(Checks::SendCheck)
        .to receive(:run)
        .with(organization: organization, amount_cents: 123)

      outcome = PayOuts::ProcessPayOut.run(pay_out: pay_out)

      expect(outcome).to be_success
      expect(pay_out.reload.processed_at).to eq Time.zone.now
    end
  end
end
