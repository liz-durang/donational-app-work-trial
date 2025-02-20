require 'rails_helper'

RSpec.describe Organizations::GetOrganizationsThatMatchPriorities, type: :query do
  let(:donor) { create(:donor) }
  let(:cause_area1) { 'global_health' }
  let(:cause_area2) { 'poverty_and_income_inequality' }
  let!(:organization1) { create(:organization, cause_area: cause_area1, deactivated_at: nil, suggested_by_donor: nil) }
  let!(:organization2) { create(:organization, cause_area: cause_area2, deactivated_at: nil, suggested_by_donor: nil) }
  let!(:deactivated_organization) { create(:organization, cause_area: cause_area1, deactivated_at: 1.day.ago, suggested_by_donor: nil) }
  let!(:suggested_organization) { create(:organization, cause_area: cause_area1, deactivated_at: nil, suggested_by_donor: donor) }

  before do
    allow(Organization).to receive(:recommendable_cause_areas).and_return([cause_area1, cause_area2])
    create(:cause_area_relevance, donor: donor, global_health: 10, poverty_and_income_inequality: 10)
    create(:cause_area_relevance, donor: donor, global_health: 10, poverty_and_income_inequality: 10)
  end

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns organizations that match the donors priorities' do
      expect(subject).to match_array([organization1, organization2])
    end

    it 'does not return deactivated organizations' do
      expect(subject).not_to include(deactivated_organization)
    end

    it 'does not return organizations suggested by the donor' do
      expect(subject).not_to include(suggested_organization)
    end
  end
end
