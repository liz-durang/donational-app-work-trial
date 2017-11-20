require 'rails_helper'

RSpec.describe Grants::ScheduleGrant do
  let(:organization) { create(:organization) }

  context 'when the scheduled pay out date is in the past' do
    let(:scheduled_at) { 1.day.ago }

    it 'does not run, and includes an error' do
      command = Grants::ScheduleGrant.run(organization: organization, scheduled_at: scheduled_at)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(scheduled_at: :after)
    end
  end

  context 'when the scheduled pay out date is in the future' do
    let(:scheduled_at) { 1.day.from_now }

    let(:donations) { double(:donations) }
    let(:donation_1) { instance_double(Donation, update: true) }
    let(:donation_2) { instance_double(Donation, update: true) }
    let(:grant) { instance_double(Grant, id: 'some_id') }

    before do
      allow(Donations::GetUnpaidDonations)
        .to receive(:call)
        .with(organization: organization)
        .and_return(donations)

      allow(donations)
       .to receive(:sum)
       .with(:amount_cents)
       .and_return(543)

      allow(donations).to receive(:each).and_yield(donation_1).and_yield(donation_2)

      allow(Donations::MarkDonationAsProcessed).to receive(:run!)
    end

    it 'creates a scheduled Grant to the organization for any unpaid donations' do
      expect(Grant)
        .to receive(:create!)
        .with(organization: organization, amount_cents: 543, scheduled_at: scheduled_at)
        .and_return(grant)

      command = Grants::ScheduleGrant.run(organization: organization, scheduled_at: scheduled_at)

      expect(command).to be_success
    end

    it 'marks the donations as paid by associating them with the grant' do
      allow(Grant).to receive(:create!).and_return(grant)

      expect(Donations::MarkDonationAsProcessed)
        .to receive(:run!)
        .with(donation: donation_1, processed_by: grant)
      expect(Donations::MarkDonationAsProcessed)
        .to receive(:run!)
        .with(donation: donation_2, processed_by: grant)

      command = Grants::ScheduleGrant.run(organization: organization, scheduled_at: scheduled_at)

      expect(command).to be_success
    end
  end
end
