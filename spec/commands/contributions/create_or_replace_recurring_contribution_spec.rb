require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Contributions::CreateOrReplaceRecurringContribution do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    Contributions::CreateOrReplaceRecurringContribution.run(params)
  end

  let(:params) do
    {
      donor: donor,
      portfolio: portfolio,
      partner: partner,
      amount_cents: 8000,
      tips_cents: 100,
      frequency: :annually,
      start_at: '2000-01-01'
    }
  end
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor, email: 'user@example.com') }
  let(:portfolio) { create(:portfolio) }
  let(:partner) { create(:partner) }

  context 'when there are no existing recurring donations for the donor' do
    it 'creates a new active recurring contribution' do
      expect { subject }.to change { RecurringContribution.count }.from(0).to(1)

      recurring_contribution = Contributions::GetActiveRecurringContribution.call(donor: donor)

      expect(recurring_contribution).to be_active
      expect(recurring_contribution.amount_cents).to eq 8000
      expect(recurring_contribution.tips_cents).to eq 100
      expect(recurring_contribution.frequency).to eq 'annually'
      expect(recurring_contribution.start_at.to_date).to eq Date.new(2000, 1, 1)
      expect(recurring_contribution.last_scheduled_at).to eq nil
      expect(recurring_contribution.partner).to eq partner
      expect(TriggerRecurringContributionUpdatedWebhook.jobs.size).to eq(1)
    end

    context 'and there is no start date provided' do
      let(:params_without_start_date) { params.merge(start_at: nil) }

      around do |spec|
        travel_to(Date.new(2010, 1, 1)) do
          spec.run
        end
      end

      it 'creates a new active recurring donation starting at the current time' do
        Contributions::CreateOrReplaceRecurringContribution.run(params_without_start_date)
        recurring_contribution = Contributions::GetActiveRecurringContribution.call(donor: donor)

        expect(TriggerRecurringContributionUpdatedWebhook.jobs.size).to eq(1)
        expect(recurring_contribution.start_at).to eq Date.new(2010, 1, 1)
      end
    end
  end

  context 'when there is an existing active recurring_contribution' do
    let!(:existing_recurring_contribution) do
      create(:recurring_contribution,
        donor: donor,
        deactivated_at: nil,
        last_scheduled_at: 1.day.ago
      )
    end

    let!(:recurring_contribution_for_other_donor) do
      create(:recurring_contribution, donor: other_donor, deactivated_at: nil)
    end

    it 'deactivates the previous recurring_contributions for the donor' do
      expect { subject }.not_to(change { recurring_contribution_for_other_donor.active? })

      expect(existing_recurring_contribution.reload).not_to be_active
    end

    it 'creates a new active recurring_contribution for the donor' do
      expect { subject }.to change { RecurringContribution.count }.from(2).to(3)

      recurring_contribution = Contributions::GetActiveRecurringContribution.call(donor: donor)
      expect(recurring_contribution).to be_active
      expect(recurring_contribution.donor).to eq donor
      expect(recurring_contribution.amount_cents).to eq 8000
      expect(recurring_contribution.partner).to eq partner
    end

    it 'copies the last_scheduled_at date from the previous plan' do
      subject

      recurring_contribution = Contributions::GetActiveRecurringContribution.call(donor: donor)
      expect(recurring_contribution.last_scheduled_at).to eq existing_recurring_contribution.reload.last_scheduled_at
    end
  end
end
