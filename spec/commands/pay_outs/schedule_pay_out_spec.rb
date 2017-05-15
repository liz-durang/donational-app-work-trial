require 'rails_helper'

RSpec.describe PayOuts::SchedulePayOut do
  let(:organization) { create(:organization) }

  context 'when the scheduled pay out date is in the past' do
    let(:scheduled_at) { 1.day.ago }

    it 'does not run, and includes an error' do
      outcome = PayOuts::SchedulePayOut.run(organization: organization, scheduled_at: scheduled_at)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(scheduled_at: :after)
    end
  end

  context 'when the scheduled pay out date is in the future' do
    let(:scheduled_at) { 1.day.from_now }

    let(:donations) { double(:donations) }
    let(:pay_out) { instance_double(PayOut) }

    before do
      allow(Donations::GetUnpaidDonations)
        .to receive(:call)
        .with(organization: organization)
        .and_return(donations)

      allow(donations)
        .to receive(:sum)
        .with(:amount_cents)
        .and_return(543)
    end

    it 'creates a scheduled PayOut to the organization for any unpaid donations' do
      expect(PayOut)
        .to receive(:create!)
        .with(organization: organization, amount_cents: 543, scheduled_at: scheduled_at)
        .and_return(pay_out)

      allow(donations).to receive(:update_all)

      outcome = PayOuts::SchedulePayOut.run(organization: organization, scheduled_at: scheduled_at)

      expect(outcome).to be_success
    end

    it 'marks the donations as paid by associating them with the pay_out' do
      allow(PayOut).to receive(:create!).and_return(pay_out)

      expect(donations).to receive(:update_all).with(pay_out: pay_out)

      outcome = PayOuts::SchedulePayOut.run(organization: organization, scheduled_at: scheduled_at)

      expect(outcome).to be_success
    end
  end
end
