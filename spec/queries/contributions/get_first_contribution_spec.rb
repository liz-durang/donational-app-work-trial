require 'rails_helper'

RSpec.describe Contributions::GetFirstContribution, type: :query do
  let(:donor) { create(:donor) }
  let!(:contribution1) { create(:contribution, donor: donor, created_at: 2.days.ago) }
  let!(:contribution2) { create(:contribution, donor: donor, created_at: 1.day.ago) }
  let!(:other_contribution) { create(:contribution, created_at: 3.days.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    it 'returns the first contribution for the given donor' do
      expect(subject).to eq(contribution1)
    end

    it 'does not return contributions for other donors' do
      expect(subject).not_to eq(other_contribution)
    end
  end
end
