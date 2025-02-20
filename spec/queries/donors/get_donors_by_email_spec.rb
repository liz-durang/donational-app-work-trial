require 'rails_helper'

RSpec.describe Donors::GetDonorsByEmail, type: :query do
  let!(:active_donor1) { create(:donor, email: 'active@example.com', deactivated_at: nil) }
  let!(:active_donor2) { create(:donor, email: 'active@example.com', deactivated_at: nil) }
  let!(:deactivated_donor) { create(:donor, email: 'active@example.com', deactivated_at: 1.day.ago) }
  let!(:other_donor) { create(:donor, email: 'other@example.com', deactivated_at: nil) }

  describe '#call' do
    subject { described_class.new.call(email: email) }

    context 'when the email is present' do
      let(:email) { 'active@example.com' }

      it 'returns active donors with the given email' do
        expect(subject).to match_array([active_donor1, active_donor2])
      end

      it 'does not return deactivated donors' do
        expect(subject).not_to include(deactivated_donor)
      end

      it 'does not return donors with a different email' do
        expect(subject).not_to include(other_donor)
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
