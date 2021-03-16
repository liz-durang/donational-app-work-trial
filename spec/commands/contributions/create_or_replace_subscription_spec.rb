require 'rails_helper'
RSpec.describe Contributions::CreateOrReplaceSubscription do
  include ActiveSupport::Testing::TimeHelpers

  before do |example|
    create(:partner, :default)
    create(:payment_method, donor: donor)
  end

  subject do
    Contributions::CreateOrReplaceSubscription.run(params)
  end

  let(:params) do
    {
      donor: donor,
      portfolio: portfolio,
      partner: partner,
      amount_cents: 8000,
      tips_cents: 100,
      frequency: :annually,
      start_at: Time.zone.parse('2000-01-01'),
      trial_amount_cents: 500
    }
  end
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor, email: 'user@example.com') }
  let(:portfolio) { create(:portfolio) }
  let(:partner) { create(:partner) }

  context 'when there are no existing recurring donations for the donor' do
    it 'creates a new active subscription' do
      Contributions::CreateOrReplaceSubscription.run(params)
      expect(Subscription.count).to eq(1)
      expect(TriggerSubscriptionWebhook.jobs.size).to eq(1)

      subscription = Contributions::GetActiveSubscription.call(donor: donor)

      expect(subscription).to be_active
      expect(subscription.amount_cents).to eq 8000
      expect(subscription.tips_cents).to eq 100
      expect(subscription.frequency).to eq 'annually'
      expect(subscription.start_at.to_date).to eq Date.new(2000, 1, 1)
      expect(subscription.last_scheduled_at).to eq nil
      expect(subscription.partner).to eq partner
      expect(subscription.partner_contribution_percentage).to eq 0
      expect(subscription.trial_amount_cents).to eq 500
      expect(subscription.trial_start_at.to_date).not_to be nil
    end

    context 'and there is no start date provided' do
      let(:params_without_start_date) { params.merge(start_at: nil) }

      around do |spec|
        travel_to(Date.new(2010, 1, 1)) do
          spec.run
        end
      end

      it 'creates a new active recurring donation starting at the current time' do
        Contributions::CreateOrReplaceSubscription.run(params_without_start_date)
        subscription = Contributions::GetActiveSubscription.call(donor: donor)

        expect(TriggerSubscriptionWebhook.jobs.size).to eq(1)
        expect(subscription.start_at).to eq Date.new(2010, 1, 1)
      end

      it "sets the portfolio to the donor's active portfolio" do
        expect(Portfolios::SelectPortfolio).to receive(:run).with(donor: donor, portfolio: portfolio)

        subject
      end
    end

    context 'and there is no trial amount cents provided' do
      let(:params_without_trial_amount_cents) { params.merge(trial_amount_cents: nil) }

      it 'creates a new active recurring donation without trial' do
        Contributions::CreateOrReplaceSubscription.run(params_without_trial_amount_cents)
        subscription = Contributions::GetActiveSubscription.call(donor: donor)

        expect(subscription.trial_amount_cents).to eq 0
        expect(subscription.trial_start_at).to eq nil
      end
    end
  end

  context 'when there is an existing active subscription' do
    let(:some_other_portfolio) { create(:portfolio) }
    let!(:existing_subscription) do
      create(:subscription,
        donor: donor,
        portfolio: some_other_portfolio,
        deactivated_at: nil,
        last_scheduled_at: 1.day.ago,
        trial_amount_cents: 300,
        trial_deactivated_at: nil,
        trial_last_scheduled_at: 1.day.ago
      )
    end

    let!(:subscription_for_other_donor) do
      create(:subscription, donor: other_donor, deactivated_at: nil)
    end

    it 'deactivates the previous subscription for the donor' do
      expect { subject }.not_to(change { subscription_for_other_donor.active? })

      expect(existing_subscription.reload).not_to be_active
    end

    it 'deactivates the previous trial for the donor' do
      expect { subject }.not_to(change { subscription_for_other_donor.active? })

      expect(existing_subscription.reload.trial_active?).to be false
    end

    it 'creates a new active subscription for the donor' do
      expect { subject }.to change { Subscription.count }.from(2).to(3)

      subscription = Contributions::GetActiveSubscription.call(donor: donor)
      expect(subscription).to be_active
      expect(subscription.donor).to eq donor
      expect(subscription.amount_cents).to eq 8000
      expect(subscription.partner).to eq partner
      expect(TriggerSubscriptionWebhook.jobs.size).to eq(1)
      expect(subscription.partner_contribution_percentage).to eq 0
      expect(subscription.trial_amount_cents).to eq 500
    end

    it 'copies the last_scheduled_at date from the previous plan' do
      subject

      subscription = Contributions::GetActiveSubscription.call(donor: donor)
      expect(subscription.last_scheduled_at).to eq existing_subscription.reload.last_scheduled_at
      expect(subscription.trial_last_scheduled_at).to eq existing_subscription.reload.trial_last_scheduled_at
    end

    it "sets the portfolio to the donor's active portfolio" do
      expect(Portfolios::SelectPortfolio).to receive(:run).with(donor: donor, portfolio: portfolio)

      subject
    end

    context 'and the new subscription is a once-off contribution' do
      let(:params) do
        {
          donor: donor,
          portfolio: portfolio,
          partner: partner,
          amount_cents: 8000,
          tips_cents: 100,
          frequency: :once,
          start_at: Time.zone.parse('2000-01-01')
        }
      end

      it 'clears out the last_scheduled_at date' do
        subject

        subscription = Contributions::GetActiveSubscription.call(donor: donor)
        expect(subscription.frequency).to eq :once
        expect(subscription.last_scheduled_at).to be nil
      end
    end
  end
end
