require 'rails_helper'

RSpec.describe PayIns::SchedulePayIn do
  context 'when the scheduled pay in date is in the past' do
    let(:subscription) { create(:subscription) }
    let(:scheduled_at) { 1.day.ago }

    it 'does not run, and includes an error' do
      outcome = PayIns::SchedulePayIn.run(subscription: subscription, scheduled_at: scheduled_at)

      expect(outcome).not_to be_success
      expect(outcome.errors.symbolic).to include(scheduled_at: :after)
    end
  end

  context 'when the scheduled pay in date is in the future' do
    let(:scheduled_at) { 1.day.from_now }
    let(:subscription) do
      create(:subscription, annual_income_cents: 53_000_00, donation_rate: 0.01)
    end

    it 'creates a scheduled PayIn for the subscription with the rounded down monthly donation' do
      expect(PayIn)
        .to receive(:create!)
        .with(subscription: subscription, amount_cents: 4_416, scheduled_at: scheduled_at)

      outcome = PayIns::SchedulePayIn.run(subscription: subscription, scheduled_at: scheduled_at)

      expect(outcome).to be_success
    end
  end
end
