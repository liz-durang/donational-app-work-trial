require 'rails_helper'

RSpec.describe Contributions::UpdateRecurringContribution do
  let(:donor) { create(:donor) }

  context 'when frequency is changed' do
    let(:recurring_contribution) do
      create(:recurring_contribution, donor: donor, frequency: :monthly)
    end

    it 'updates recurring_contribution frequency' do
      command = Contributions::UpdateRecurringContribution.run(
        recurring_contribution: recurring_contribution,
        frequency: 'quarterly'
      )

      expect(command).to be_success
      expect(recurring_contribution.reload.frequency).to eq 'quarterly'
    end
  end

  context 'when amount is changed' do
    let(:recurring_contribution) do
      create(:recurring_contribution, donor: donor, amount_cents: 2600)
    end

    it 'updates recurring_contribution amount' do
      command = Contributions::UpdateRecurringContribution.run(
        recurring_contribution: recurring_contribution,
        amount_cents: 5000
      )

      expect(command).to be_success
      expect(recurring_contribution.reload.amount_cents).to eq 5000
    end
  end
end
