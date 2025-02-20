require 'rails_helper'

RSpec.describe SearchableOrganizations::GetSearchableOrganizationByEin, type: :query do
  let!(:searchable_organization) { create(:searchable_organization, ein: '123456789') }

  describe '#call' do
    subject { described_class.new.call(ein: ein) }

    context 'when the EIN is present' do
      let(:ein) { '123456789' }

      it 'returns the searchable organization with the given EIN' do
        expect(subject).to eq(searchable_organization)
      end
    end

    context 'when the EIN is blank' do
      let(:ein) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the searchable organization with the given EIN does not exist' do
      let(:ein) { 'nonexistent_ein' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
