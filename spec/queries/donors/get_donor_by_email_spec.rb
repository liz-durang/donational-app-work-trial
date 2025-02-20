require 'rails_helper'

RSpec.describe Donors::GetDonorByEmail, type: :query do
  let!(:active_donor) { create(:donor, email: 'active@example.com', deactivated_at: nil) }
  let!(:deactivated_donor) { create(:donor, email: 'deactivated@example.com', deactivated_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(email: email) }

    context 'when the email is present' do
      context 'when the donor is active' do
        let(:email) { 'active@example.com' }

        it 'returns the active donor with the given email' do
          expect(subject).to eq(active_donor)
        end
      end

      context 'when the donor is deactivated' do
        let(:email) { 'deactivated@example.com' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when the donor does not exist' do
        let(:email) { 'nonexistent@example.com' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    context 'when the email is blank' do
      let(:email) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
