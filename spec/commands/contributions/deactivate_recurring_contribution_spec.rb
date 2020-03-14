require 'rails_helper'

RSpec.describe Contributions::DeactivateRecurringContribution do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do |example|
    create(:partner, :default)
  end

  context 'when is cancelled' do
    let(:recurring_contribution) do
      create(:recurring_contribution, donor: donor, deactivated_at: nil)
    end

    it 'deactivates recurring_contribution' do
      command = Contributions::DeactivateRecurringContribution.run(recurring_contribution: recurring_contribution)

      expect(command).to be_success
      expect(recurring_contribution.reload).not_to be_active
      expect(TriggerRecurringContributionCancelledWebhook.jobs.size).to eq(1)
    end
  end
end
