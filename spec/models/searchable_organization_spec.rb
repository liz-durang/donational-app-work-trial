require 'rails_helper'

RSpec.describe SearchableOrganization, type: :model do
  describe 'searchkick' do
    it 'responds to searchkick' do
      expect(SearchableOrganization).to respond_to(:searchkick)
    end
  end

  describe 'methods' do
    describe '#search_data' do
      let(:organization) { build(:searchable_organization, ein: '123456789', name: 'Test Organization') }

      it 'returns a hash with ein and name' do
        expect(organization.search_data).to eq({ ein: '123456789', name: 'Test Organization' })
      end
    end

    describe '#formatted_ein' do
      let(:organization) { build(:searchable_organization, ein: '123456789') }

      it 'returns the formatted EIN' do
        expect(organization.formatted_ein).to eq('12-3456789')
      end
    end

    describe '#formatted_name' do
      let(:organization) { build(:searchable_organization, name: 'test organization') }

      it 'returns the formatted name' do
        expect(organization.formatted_name).to eq('Test Organization')
      end
    end

    describe '.search_for' do
      let!(:organization1) { create(:searchable_organization, name: 'Test Organization One') }
      let!(:organization2) { create(:searchable_organization, name: 'Test Organization Two') }

      before do
        SearchableOrganization.reindex
      end

      it 'returns search results for the given query' do
        search = described_class.search_for('Test')
        expect(search.results).to include(organization1, organization2)
      end

      it 'limits the number of search results' do
        search = described_class.search_for('Test', limit: 1)
        expect(search.size).to eq(1)
      end
    end
  end
end
