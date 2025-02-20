require 'rails_helper'

RSpec.describe Organizations::GetRecommendedOrganizations, type: :query do
  let!(:organization1) { create(:organization, cause_area: 'poverty_and_income_inequality', name: 'Alpha', deactivated_at: nil, suggested_by_donor: nil) }
  let!(:organization2) { create(:organization, cause_area: 'climate_and_environment', name: 'Beta', deactivated_at: nil, suggested_by_donor: nil) }
  let!(:organization3) { create(:organization, cause_area: 'animal_welfare', name: 'Gamma', deactivated_at: nil, suggested_by_donor: nil) }
  let!(:deactivated_organization) { create(:organization, cause_area: 'poverty_and_income_inequality', name: 'Delta', deactivated_at: 1.day.ago, suggested_by_donor: nil) }
  let!(:suggested_organization) { create(:organization, cause_area: 'poverty_and_income_inequality', name: 'Epsilon', deactivated_at: nil, suggested_by_donor: create(:donor)) }

  describe '#call' do
    subject { described_class.new.call }

    it 'returns active organizations not suggested by donors, ordered by cause area and name' do
      expect(subject).to eq([organization3, organization2, organization1])
    end

    it 'does not return deactivated organizations' do
      expect(subject).not_to include(deactivated_organization)
    end

    it 'does not return organizations suggested by donors' do
      expect(subject).not_to include(suggested_organization)
    end
  end
end
