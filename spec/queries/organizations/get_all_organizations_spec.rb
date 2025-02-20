require 'rails_helper'

RSpec.describe Organizations::GetAllOrganizations, type: :query do
  let!(:organization1) { create(:organization, name: 'Alpha') }
  let!(:organization2) { create(:organization, name: 'Beta') }
  let!(:organization3) { create(:organization, name: 'Gamma') }

  describe '#call' do
    subject { described_class.new.call }

    it 'returns all organizations ordered by name ascending' do
      expect(subject).to eq([organization1, organization2, organization3])
    end
  end
end
