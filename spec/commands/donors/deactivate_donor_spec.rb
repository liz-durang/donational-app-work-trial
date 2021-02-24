require 'rails_helper'

RSpec.describe Donors::DeactivateDonor do
  let(:donor) { create(:donor, email: 'user@example.com') }
  let(:subscription) { create(:subscription, donor: donor, deactivated_at: nil) }

  before do |example|
    create(:partner, :default)
  end

  it 'deactivates donor' do
    expect(donor).to be_active

    outcome = Donors::DeactivateDonor.run(donor: donor)

    expect(outcome).to be_success
    expect(donor.reload).not_to be_active
  end

  it "deactivates donor's active subscriptions" do
    expect(subscription).to be_active

    outcome = Donors::DeactivateDonor.run(donor: donor)

    expect(outcome).to be_success
    expect(subscription.reload).not_to be_active
  end
end
