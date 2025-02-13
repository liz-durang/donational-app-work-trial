# == Schema Information
#
# Table name: subscriptions
#
#  id                              :uuid             not null, primary key
#  donor_id                        :uuid
#  portfolio_id                    :uuid
#  start_at                        :datetime         not null
#  deactivated_at                  :datetime
#  frequency                       :string
#  amount_cents                    :integer
#  tips_cents                      :integer          default(0)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  last_reminded_at                :datetime
#  last_scheduled_at               :datetime
#  partner_id                      :uuid
#  partner_contribution_percentage :integer          default(0)
#  amount_currency                 :string           default("usd"), not null
#

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'associations' do
    it { should belong_to(:donor) }
    it { should belong_to(:portfolio) }
    it { should belong_to(:partner) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount_currency) }
  end

  describe 'enums' do
    describe '.frequency' do
      it 'defines the enumerized attribute' do
        expect(described_class.enumerized_attributes[:frequency].values)
          .to match_array(%w[monthly quarterly annually once])
      end
    
      it 'validates inclusion in the enumerized values' do
        subscription = described_class.new(frequency: 'invalid_value')
        expect(subscription).not_to be_valid
        expect(subscription.errors[:frequency])
          .to include('is not included in the list')
      end
    
      context 'with valid values' do
        %w[monthly quarterly annually once].each do |frequency|
          it "allows #{frequency} as a valid frequency" do
            subscription = build(:subscription, frequency: frequency) 
            expect(subscription).to be_valid
          end
        end
      end
    end
  end

  describe 'delegations' do
    it { should delegate_method(:name).to(:donor).with_prefix }
    it { should delegate_method(:email).to(:donor).with_prefix }
  end

  describe 'methods' do
    describe '#active?' do
      let(:subscription) { build(:subscription, deactivated_at: deactivated_at, start_at: start_at) }

      context 'when deactivated_at is nil and future_contribution_scheduled? is true' do
        let(:deactivated_at) { nil }
        let(:start_at) { 1.day.ago }

        before do
          allow(subscription).to receive(:future_contribution_scheduled?).and_return(true)
        end

        it 'returns true' do
          expect(subscription.active?).to be true
        end
      end

      context 'when deactivated_at is not nil' do
        let(:deactivated_at) { Time.current }
        let(:start_at) { 1.day.ago }

        it 'returns false' do
          expect(subscription.active?).to be false
        end
      end

      context 'when future_contribution_scheduled? is false' do
        let(:deactivated_at) { nil }
        let(:start_at) { 1.day.ago }

        before do
          allow(subscription).to receive(:future_contribution_scheduled?).and_return(false)
        end

        it 'returns false' do
          expect(subscription.active?).to be false
        end
      end
    end

    describe '#started?' do
      let(:subscription) { build(:subscription, start_at: start_at) }

      context 'when start_at is nil' do
        let(:start_at) { nil }

        it 'returns true' do
          expect(subscription.started?).to be true
        end
      end

      context 'when start_at is in the past' do
        let(:start_at) { 1.day.ago }

        it 'returns true' do
          expect(subscription.started?).to be true
        end
      end

      context 'when start_at is today' do
        let(:start_at) { Date.today }

        it 'returns true' do
          expect(subscription.started?).to be true
        end
      end

      context 'when start_at is in the future' do
        let(:start_at) { 1.day.from_now }

        it 'returns false' do
          expect(subscription.started?).to be false
        end
      end
    end

    describe '#future_contribution_scheduled?' do
      let(:subscription) { build(:subscription) }

      context 'when next_contribution_at is nil' do
        before do
          allow(subscription).to receive(:next_contribution_at).and_return(nil)
        end

        it 'returns false' do
          expect(subscription.future_contribution_scheduled?).to be false
        end
      end

      context 'when next_contribution_at is in the past' do
        before do
          allow(subscription).to receive(:next_contribution_at).and_return(1.day.ago)
        end

        it 'returns false' do
          expect(subscription.future_contribution_scheduled?).to be false
        end
      end

      context 'when next_contribution_at is today' do
        before do
          allow(subscription).to receive(:next_contribution_at).and_return(Date.today)
        end

        it 'returns true' do
          expect(subscription.future_contribution_scheduled?).to be true
        end
      end

      context 'when next_contribution_at is in the future' do
        before do
          allow(subscription).to receive(:next_contribution_at).and_return(1.day.from_now)
        end

        it 'returns true' do
          expect(subscription.future_contribution_scheduled?).to be true
        end
      end
    end

    describe '#amount_dollars' do
      let(:subscription) { build(:subscription, amount_cents: 2500) }

      it 'returns the amount in dollars' do
        expect(subscription.amount_dollars).to eq(25.0)
      end
    end

    describe '#next_contribution_at' do
      around do |spec|
        travel_to(now) do
          spec.run
        end
      end

      context 'when the start date is in the future' do
        let(:start_at) { Date.parse('2001-01-01') }
        let(:now) { Date.parse('2000-01-01') }

        context 'and the frequency is monthly' do
          context 'and start day is before the 15th' do
            it 'returns 15th of the month of start date' do
              donation = build(:subscription, start_at: start_at, frequency: :monthly)
              expect(donation.next_contribution_at).to eq Date.parse('2001-01-15')
            end
          end

          context 'and start day is after the 15th' do
            let(:start_at) { Date.parse('2001-01-16') }

            it 'returns the next 15th of the month after start date' do
              donation = build(:subscription, start_at: start_at, frequency: :monthly)
              expect(donation.next_contribution_at).to eq Date.parse('2001-02-15')
            end
          end
        end

        context 'and the frequency is quarterly' do
          it 'returns the start date' do
            donation = build(:subscription, start_at: start_at, frequency: :quarterly)
            expect(donation.next_contribution_at).to eq Date.parse('2001-01-01')
          end
        end

        context 'and the frequency is annually' do
          it 'returns the start date' do
            donation = build(:subscription, start_at: start_at, frequency: :annually)
            expect(donation.next_contribution_at).to eq Date.parse('2001-01-01')
          end
        end
      end

      context 'when the start date is in a previous month' do
        let(:start_at) { Date.parse('2000-01-01') }

        context 'and the frequency is monthly' do
          let(:monthly_contribution) { build(:subscription, start_at: start_at, frequency: :monthly) }

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
          let(:quarterly_contribution) { build(:subscription, start_at: start_at, frequency: :quarterly) }

          it 'is the first day of the next quarter' do
            expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
          end
        end

        context 'and the frequency is annually' do
          let(:now) { Date.parse('2000-03-21') }
          let(:annually_contribution) { build(:subscription, start_at: start_at, frequency: :annually) }

          it 'is the first day of next year' do
            expect(annually_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
          end
        end
      end

      context 'when the start date was in the current month' do
        let(:start_at) { Date.parse('2000-01-01') }
        let(:monthly_contribution) { build(:subscription, start_at: start_at, frequency: :monthly) }

        context 'and the frequency is monthly' do
          context 'and the current day is before the 15th of the month' do
            let(:now) { Date.parse('2000-01-01') }

            it 'is the 15th of this month' do
              expect(monthly_contribution.next_contribution_at).to eq Date.parse('2000-01-15')
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
          let(:quarterly_contribution) { build(:subscription, start_at: start_at, frequency: :quarterly) }

          it 'is the first day of the next quarter' do
            expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2000-04-01')
          end
        end

        context 'and the frequency is annually' do
          let(:now) { Date.parse('2000-01-02') }
          let(:quarterly_contribution) { build(:subscription, start_at: start_at, frequency: :annually) }

          it 'is the first day of next year' do
            expect(quarterly_contribution.next_contribution_at).to eq Date.parse('2001-01-01')
          end
        end
      end
    end

    describe '#trial_active?' do
      let(:subscription) { build(:subscription, trial_deactivated_at: trial_deactivated_at) }

      context 'when trial_deactivated_at is nil and trial_amount_cents == 100' do
        let(:subscription) { build(:subscription, trial_deactivated_at: trial_deactivated_at, trial_amount_cents: 100) }
        let(:trial_deactivated_at) { nil }


        it 'returns true' do
          expect(subscription.trial_active?).to be true
        end
      end

      context 'when trial_deactivated_at is not nil' do
        let(:trial_deactivated_at) { Time.current }

        it 'returns false' do
          expect(subscription.trial_active?).to be false
        end
      end
    end

    describe '#trial_amount_dollars' do
      let(:subscription) { build(:subscription, trial_amount_cents: 1500) }

      it 'returns the trial amount in dollars' do
        expect(subscription.trial_amount_dollars).to eq(15.0)
      end
    end

    describe '#trial_future_contribution_scheduled?' do
      let(:subscription) { build(:subscription) }
    
      context 'when trial_next_contribution_at is nil' do
        before do
          allow(subscription).to receive(:trial_next_contribution_at).and_return(nil)
        end
    
        it 'returns false' do
          expect(subscription.trial_future_contribution_scheduled?).to be false
        end
      end
    
      context 'when trial_next_contribution_at is in the past' do
        before do
          allow(subscription).to receive(:trial_next_contribution_at).and_return(1.day.ago)
        end
    
        it 'returns false' do
          expect(subscription.trial_future_contribution_scheduled?).to be false
        end
      end
    
      context 'when trial_next_contribution_at is today' do
        before do
          allow(subscription).to receive(:trial_next_contribution_at).and_return(Date.today)
        end
    
        it 'returns true' do
          expect(subscription.trial_future_contribution_scheduled?).to be true
        end
      end
    
      context 'when trial_next_contribution_at is in the future' do
        before do
          allow(subscription).to receive(:trial_next_contribution_at).and_return(1.day.from_now)
        end
    
        it 'returns true' do
          expect(subscription.trial_future_contribution_scheduled?).to be true
        end
      end
    end

    describe '#trial_next_contribution_at' do
      let(:subscription) { build(:subscription, trial_start_at: trial_start_at) }

      context 'when trial is not active' do
        let(:trial_start_at) { 1.month.ago }
        before do
          allow(subscription).to receive(:trial_active?).and_return(false)
        end

        it 'returns nil' do
          expect(subscription.trial_next_contribution_at).to be_nil
        end
      end

      context 'when trial is active' do
        before do
          allow(subscription).to receive(:trial_active?).and_return(true)
        end
          
        context 'when trial_start_at is in the past' do
          let(:trial_start_at) { 1.month.ago }
  
          # TODO: Fix Flaky/Failing spec.
          xit 'returns the next 15th of the month after today' do
            expect(subscription.trial_next_contribution_at).to eq Date.new(Date.today.year, Date.today.month, 15).next_month
          end
        end
  
        context 'when trial_start_at is in the future' do
          let(:trial_start_at) { 1.month.from_now }
          
          # TODO: Fix Flaky/Failing spec.
          xit 'returns the next 15th of the month after trial_start_at' do
            expect(subscription.trial_next_contribution_at).to eq Date.new(trial_start_at.year, trial_start_at.month, 15).next_month
          end
        end
      end
    end
  end
end
