require 'rails_helper'

RSpec.describe Donors::GetDonorByUsername, type: :query do
  let!(:donor) { create(:donor, username: 'john_doe') }

  describe '#call' do
    subject { described_class.new.call(username: username) }

    context 'when the username is present' do
      let(:username) { 'john_doe' }

      it 'returns the donor with the given username' do
        expect(subject).to eq(donor)
      end
    end

    context 'when the username is blank' do
      let(:username) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the donor with the given username does not exist' do
      let(:username) { 'nonexistent_user' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
