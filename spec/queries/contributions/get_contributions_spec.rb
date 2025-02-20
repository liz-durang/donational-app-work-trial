require 'rails_helper'

RSpec.describe Contributions::GetContributions, type: :query do
  let(:donor) { create(:donor) }
  let!(:contribution1) { create(:contribution, donor: donor, created_at: 2.days.ago) }
  let!(:contribution2) { create(:contribution, donor: donor, created_at: 1.day.ago) }
  let!(:other_contribution) { create(:contribution, created_at: 3.days.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns contributions for the given donor' do
      expect(subject).to match_array([contribution1, contribution2])
    end

    it 'does not return contributions for other donors' do
      expect(subject).not_to include(other_contribution)
    end

    it 'returns contributions in descending order of creation' do
      expect(subject).to eq([contribution2, contribution1])
    end

    it 'preloads donations' do
      expect(subject.first.association(:donations)).to be_loaded
    end

    it 'preloads organizations' do
      expect(subject.first.association(:organizations)).to be_loaded
    end
  end
end
