require 'rails_helper'

RSpec.describe Contributions::MigrateRecurringContributionToNewPartner do
  let(:donor) { create(:donor, email: 'user@example.com') }

  before do |example|
    create(:partner, name: "Old Partner")
  end

  context 'when there is a new partner' do
    let(:recurring_contribution) do
      create(:recurring_contribution, donor: donor, partner: Partner.find_by(name: "Old Partner"), deactivated_at: nil)
    end

    let(:new_partner) { create(:partner, name: "New Partner") }

    it 'migrates the recurring contribution' do
      expect(recurring_contribution.partner.name).to eq "Old Partner"
      command = Contributions::MigrateRecurringContributionToNewPartner.run(recurring_contribution: recurring_contribution, partner: new_partner)
      expect(command).to be_success
      expect(Contributions::GetRecurringContributionById.call(id: recurring_contribution.id).deactivated_at).to be_present
      expect(Contributions::GetActiveRecurringContribution.call(donor: recurring_contribution.donor).partner.name).to eq "New Partner"
    end
  end
end
