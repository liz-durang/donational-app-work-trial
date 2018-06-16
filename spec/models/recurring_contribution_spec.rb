# == Schema Information
#
# Table name: recurring_contributions
#
#  id             :uuid             not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  start_at       :datetime         not null
#  deactivated_at :datetime
#  frequency      :string
#  amount_cents   :integer
#  tips_cents     :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe RecurringContribution, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  context '#next_contribution_at' do
    around do |spec|
      travel_to(now) do
        spec.run
      end
    end

    context 'when the start date is in the future' do
      let(:start_at) { Date.parse('2001-01-01') }
      let(:now) { Date.parse('2000-01-01') }

      it 'returns the start date' do
          donation = build(:recurring_contribution, start_at: start_at)
          expect(donation.next_contribution_at).to eq Date.parse('2001-01-01')
      end
    end

    context 'when the start date is in a previous month' do
      let(:start_at) { Date.parse('2000-01-01') }

      context 'and the frequency is monthly' do
        let(:monthly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :monthly) }

        context 'and the current day is before the 15th of the month' do
          let(:now) { Date.parse('2000-02-07') }

          it 'is the 15th of this month' do
            expect(monthly_contribution.next_contribution_at).to eq Date.parse('2000-02-15')
          end
        end

        context 'and the current day is after the 15th of the month' do
          let(:now) { Date.parse('2000-02-18') }

          it 'is the 15th of the next month' do
            expect(monthly_contribution.next_contribution_at).to eq Date.parse('2000-03-15')
          end
        end
      end

      context 'and the frequency is quarterly' do
        let(:now) { Date.parse('2000-10-07') }
        let(:quarterly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :quarterly) }

        it 'is the first day of the next quarter' do
          expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
        end
      end

      context 'and the frequency is annually' do
        let(:now) { Date.parse('2000-03-21') }
        let(:quarterly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :annually) }

        it 'is the first day of next year' do
          expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
        end
      end
    end

    context 'when the start date was in the current month' do
      let(:start_at) { Date.parse('2000-01-01') }
      let(:monthly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :monthly) }

      context 'and the frequency is monthly' do
        context 'and the current day is before the 15th of the month' do
          let(:now) { Date.parse('2000-01-01') }

          it 'is the 15th of the next month' do
            expect(monthly_contribution.next_contribution_at).to eq Date.parse('2000-02-15')
          end
        end

        context 'and the current day is after the 15th of the month' do
          let(:now) { Date.parse('2000-01-18') }

          it 'is the 15th of the next month' do
            expect(monthly_contribution.next_contribution_at).to eq Date.parse('2000-02-15')
          end
        end
      end

      context 'and the frequency is quarterly' do
        let(:now) { Date.parse('2000-01-02') }
        let(:quarterly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :quarterly) }

        it 'is the first day of the next quarter' do
          expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2000-04-01')
        end
      end

      context 'and the frequency is annually' do
        let(:now) { Date.parse('2000-01-02') }
        let(:quarterly_contribution) { build(:recurring_contribution, start_at: start_at, frequency: :annually) }

        it 'is the first day of next year' do
          expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
        end
      end
    end
  end
end
