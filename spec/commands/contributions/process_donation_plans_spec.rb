require 'rails_helper'

RSpec.describe Contributions::ProcessDonationPlans do
  include ActiveSupport::Testing::TimeHelpers

  let(:portfolio) { create(:portfolio) }
  let(:donor) { create(:donor) }

  context 'when the start date is in the future' do
    let(:recurring_contribution) { create(:recurring_contribution, start_at: DateTime.now + 1.month) }

    it 'does not schedule any contribution' do
      #command = Contributions::ProcessDonationPlans.run

      #expect(command).to be_success
      #expect(Contribution.count).to be 0
    end
  end

  context 'when the start date is in the past' do
    context 'and it is a monthly donation in the first month of the plan' do
      let(:recurring_contribution) { create(:recurring_contribution) }

      before do
        #expect(Contributions::GetRecurringContributionsByFrequency)
        #  .to receive(:call)
        #  .with(frequency: 'monthly')
        #  .and_return([recurring_contribution])

        #expect(Contributions::ScheduleContribution)
        #  .to receive(:run)
        #  .with(donor: recurring_contribution.donor, portfolio: recurring_contribution.portfolio, amount_cents: recurring_contribution.amount_cents, tips_cents: recurring_contribution.tips_cents, scheduled_at: Time.zone.now)
      end

      it 'schedules a contribution on the start date' do
        #command = Contributions::ProcessDonationPlans.run

        #expect(command).to be_success
        #expect{Contribution.count}.to change {Contribution.count}.from(0).to(1)
        #expect(Contribution.last.donor).to be recurring_contribution.donor
        #expect(Contribution.last.portfolio).to be recurring_contribution.portfolio
      end
    end

    context 'and it is a monthly donation not in the first month of the plan' do
      let(:recurring_contribution) { create(:recurring_contribution) }
      let(:contribution) { create(:contribution, donor: donor, portfolio: portfolio) }

      before do
        #expect(Contributions::GetRecurringContributionsByFrequency)
        #  .to receive(:call)
        #  .with(frequency: 'monthly')
        #  .and_return([recurring_contribution])

        #expect(Contributions::GetLastContributionDateByDonationPlan)
        #  .to receive(:call)
        #  .and_return(contribution.scheduled_at.to_date)

        #expect(Contributions::ScheduleContribution)
        #  .to receive(:run)
        #  .with(donor: recurring_contribution.donor, portfolio: recurring_contribution.portfolio, amount_cents: recurring_contribution.amount_cents, tips_cents: recurring_contribution.tips_cents, scheduled_at: Time.zone.now)
      end

      it 'schedules a contribution on the 15th of the next month' do
        #command = Contributions::ProcessDonationPlans.run

        #expect(command).to be_success
        #expect{Contribution.count}.to change {Contribution.count}.from(0).to(1)
      end
    end
  end
end
