require 'rails_helper'

RSpec.describe Contributions::HasPreviousOrUpcomingContribution, type: :query do
  let(:donor) { create(:donor) }
  let!(:previous_contribution) { create(:contribution, donor: donor) }
  let!(:planned_contribution) { create(:subscription, donor: donor, deactivated_at: nil) }
  let!(:deactivated_subscription) { create(:subscription, donor: donor, deactivated_at: 1.day.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    context 'when the donor has a previous contribution' do
      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when the donor has a planned contribution' do
      before { previous_contribution.destroy }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when the donor has no previous or planned contributions' do
      before do
        previous_contribution.destroy
        planned_contribution.destroy
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when the donor only has deactivated subscriptions' do
      before do
        previous_contribution.destroy
        planned_contribution.destroy
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end
end
