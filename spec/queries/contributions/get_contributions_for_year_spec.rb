require 'rails_helper'

RSpec.describe Contributions::GetContributionsForYear do
  let(:donor) { create(:donor) }
  let(:other_donor) { create(:donor) }
  subject { Contributions::GetContributionsForYear.call(donor: donor, year: 2018) }

  context 'when the donor has no contributions in the specified year' do
    before do
      create(:contribution, donor: donor, processed_at: '2017-06-01')
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when the donor has contributions in the specified year' do
    let!(:excluded_contribution) { create(:contribution, donor: donor, processed_at: '2017-06-01') }
    let!(:contribution_from_other_donor) { create(:contribution, donor: other_donor, processed_at: '2018-06-01') }
    let!(:included_contribution_1) { create(:contribution, donor: donor, processed_at: '2018-04-01') }
    let!(:included_contribution_2) { create(:contribution, donor: donor, processed_at: '2018-08-01') }

    it 'returns a relation containing the contributions' do
      expect(subject).not_to include(excluded_contribution)
      expect(subject).not_to include(contribution_from_other_donor)
      expect(subject).to include(included_contribution_1)
      expect(subject).to include(included_contribution_2)
    end
  end
end
