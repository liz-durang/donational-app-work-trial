require 'rails_helper'

RSpec.describe Donations::MarkDonationAsProcessed do
  let(:donation) { create(:donation) }
  let(:pay_out) { create(:pay_out) }

  it 'associates the donation with the pay out' do
    outcome = Donations::MarkDonationAsProcessed.run(donation: donation, processed_by: pay_out)

    expect(outcome).to be_success
    expect(donation.pay_out).to eq pay_out
  end
end
