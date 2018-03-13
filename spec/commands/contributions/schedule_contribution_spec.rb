require 'rails_helper'

RSpec.describe Contributions::ScheduleContribution do
  context 'when the scheduled pay in date is in the past' do
    let(:portfolio) { create(:portfolio) }
    let(:scheduled_at) { 1.day.ago }

    it 'does not run, and includes an error' do
      command = Contributions::ScheduleContribution.run(portfolio: portfolio, scheduled_at: scheduled_at)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(scheduled_at: :after)
    end
  end

  context 'when the scheduled pay in date is in the future' do
    let(:scheduled_at) { 1.day.from_now }
    let(:portfolio) do
      create(:portfolio, contribution_amount_cents: 1234, contribution_platform_fee_cents: 200)
    end

    it 'creates a scheduled Contribution for the portfolio with the contribution amount' do
      expect(Contribution)
        .to receive(:create!)
        .with(portfolio: portfolio, amount_cents: 1234, platform_fee_cents: 200, cheduled_at: scheduled_at)

      command = Contributions::ScheduleContribution.run(portfolio: portfolio, scheduled_at: scheduled_at)

      expect(command).to be_success
    end
  end
end
