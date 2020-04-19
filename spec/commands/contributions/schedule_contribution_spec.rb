# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::ScheduleContribution do
  include ActiveSupport::Testing::TimeHelpers

  let(:portfolio) { create(:portfolio) }
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:params) do
    {
      donor: donor,
      portfolio: portfolio,
      partner: partner,
      amount_cents: 1234,
      tips_cents: 200,
      scheduled_at: scheduled_at
    }
  end

  context 'when the scheduled pay in date is not present' do
    let(:scheduled_at) { nil }

    it 'does not run, and includes an error' do
      command = described_class.run(params)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(scheduled_at: :nils)
    end
  end

  context 'when the scheduled pay in date is in the future' do
    let(:scheduled_at) { 1.day.from_now }

    it 'creates a scheduled Contribution for the portfolio with the contribution amount' do
      expect(Contribution)
        .to receive(:create!)
        .with(
          donor: donor,
          portfolio: portfolio,
          partner: partner,
          amount_cents: 1234,
          tips_cents: 200,
          scheduled_at: scheduled_at,
          external_reference_id: nil,
          processed_at: nil,
          receipt: nil,
          partner_contribution_percentage: 0,
          amount_currency: partner.currency
        )

      command = described_class.run(params)

      expect(command).to be_success
    end
  end
end
