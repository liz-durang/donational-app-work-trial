require 'rails_helper'

RSpec.describe Donations::MarkDonationAsProcessed do
  let(:donation) { create(:donation) }
  let(:grant) { create(:grant) }

  it 'associates the donation with the pay out' do
    command = Donations::MarkDonationAsProcessed.run(donation: donation, processed_by: grant)

    expect(command).to be_success
    expect(donation.grant).to eq grant
  end
end
