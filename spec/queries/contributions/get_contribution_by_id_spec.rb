require 'rails_helper'

RSpec.describe Contributions::GetContributionById, type: :query do
  let(:contribution) { create(:contribution) }

  describe '#call' do
    subject { described_class.new.call(id: contribution_id) }

    context 'when the id is present' do
      let(:contribution_id) { contribution.id }

      it 'returns the contribution with the given id' do
        expect(subject).to eq(contribution)
      end
    end

    context 'when the id is blank' do
      let(:contribution_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the contribution with the given id does not exist' do
      let(:contribution_id) { -1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
