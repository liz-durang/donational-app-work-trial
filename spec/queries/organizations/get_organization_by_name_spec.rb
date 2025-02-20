require 'rails_helper'

RSpec.describe Organizations::GetOrganizationByName, type: :query do
  let!(:organization) { create(:organization, name: 'Test Organization') }

  describe '#call' do
    subject { described_class.new.call(name: name) }

    context 'when the name is present' do
      let(:name) { 'Test Organization' }

      it 'returns the organization with the given name' do
        expect(subject).to eq(organization)
      end
    end

    context 'when the name is blank' do
      let(:name) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the organization with the given name does not exist' do
      let(:name) { 'Nonexistent Organization' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
