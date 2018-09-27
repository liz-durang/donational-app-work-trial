require 'rails_helper'

RSpec.describe Grants::ScheduleGrant do
  let(:organization) { create(:organization) }

  context 'when there are unpaid donations' do
    let(:donation_1) { create(:donation, organization: organization, amount_cents: 272, grant: nil) }
    let(:donation_2) { create(:donation, organization: organization, amount_cents: 271, grant: nil) }
    let(:donations) { { organization => [donation_1, donation_2] } }
    let(:grant) { instance_double(Grant, id: 'some_id') }
    let(:successful_command) { double(success?: true) }

    before do
      allow(Donations::GetUnpaidDonations)
        .to receive(:call)
        .and_return(donations)

      allow([donation_1, donation_2])
       .to receive(:sum)
       .with(:amount_cents)
       .and_return(543)

      allow(Donations::MarkDonationAsProcessed).to receive(:run).and_return(successful_command)
    end

    it 'creates a scheduled Grant to the organization for unpaid donations' do
      expect(Grant)
        .to receive(:create!)
        .with(organization: organization, amount_cents: 543)
        .and_return(grant)

      command = Grants::ScheduleGrant.run

      expect(command).to be_success
    end

    it 'marks the donations as paid by associating them with the grant' do
      allow(Grant).to receive(:create!).and_return(grant)

      expect(Donations::MarkDonationAsProcessed)
        .to receive(:run)
        .with(donation: donation_1, processed_by: grant)
        .and_return(successful_command)
      expect(Donations::MarkDonationAsProcessed)
        .to receive(:run)
        .with(donation: donation_2, processed_by: grant)
        .and_return(successful_command)

      command = Grants::ScheduleGrant.run

      expect(command).to be_success
    end
  end
end
