require 'rails_helper'

RSpec.describe Donors::DeactivateDonor do
  let(:donor) { create(:donor, email: 'user@example.com') }
  let(:subscriptions) do
    [
      create(:subscription, donor:, deactivated_at: nil, start_at: 1.year.from_now),
      create(:subscription, donor:, deactivated_at: nil, start_at: 1.year.ago, frequency: :once)
    ]
  end
  let(:trials) do
    [
      create(:subscription, donor:, trial_deactivated_at: nil, trial_amount_cents: 1000, start_at: 1.year.from_now),
      create(:subscription, donor:, trial_deactivated_at: nil, trial_amount_cents: 1000, start_at: 1.year.ago)
    ]
  end

  before do
    create(:partner, :default)
  end

  it 'deactivates donor' do
    expect(donor).to be_active

    outcome = Donors::DeactivateDonor.run(donor:)

    expect(outcome).to be_success
    expect(donor.reload).not_to be_active
  end

  it "deactivates donor's subscriptions, both active and inactive" do
    expect(subscriptions.select(&:active?).count).to eq(1)
    expect(subscriptions.reject(&:active?).count).to eq(1)

    outcome = Donors::DeactivateDonor.run(donor:)

    expect(outcome).to be_success
    subscriptions.each do |subscription|
      expect(subscription.reload).not_to be_active
      expect(subscription.deactivated_at).not_to be_nil
    end
  end

  it "deactivates donor's trial subscriptions, both active and inactive" do
    expect(trials.select(&:trial_active?).count).to eq(1)
    expect(trials.reject(&:trial_active?).count).to eq(1)

    outcome = Donors::DeactivateDonor.run(donor:)

    expect(outcome).to be_success

    trials.each do |trial|
      expect(trial.reload).not_to be_trial_active
      expect(trial.trial_deactivated_at).not_to be_nil
    end
  end
end
