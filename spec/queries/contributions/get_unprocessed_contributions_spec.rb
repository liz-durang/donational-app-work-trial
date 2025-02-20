require 'rails_helper'

RSpec.describe Contributions::GetUnprocessedContributions, type: :query do
  let!(:unprocessed_contribution1) { create(:contribution, processed_at: nil, failed_at: nil, scheduled_at: 1.day.ago) }
  let!(:unprocessed_contribution2) { create(:contribution, processed_at: nil, failed_at: nil, scheduled_at: 2.days.ago) }
  let!(:processed_contribution) { create(:contribution, processed_at: 1.day.ago, failed_at: nil, scheduled_at: 1.day.ago) }
  let!(:failed_contribution) { create(:contribution, processed_at: nil, failed_at: 1.day.ago, scheduled_at: 1.day.ago) }
  let!(:future_contribution) { create(:contribution, processed_at: nil, failed_at: nil, scheduled_at: 1.day.from_now) }

  describe '#call' do
    subject { described_class.new.call(scheduled_after: 3.days.ago, scheduled_before: Time.now) }

    it 'returns unprocessed contributions within the scheduled range' do
      expect(subject).to match_array([unprocessed_contribution1, unprocessed_contribution2])
    end

    it 'does not return processed contributions' do
      expect(subject).not_to include(processed_contribution)
    end

    it 'does not return failed contributions' do
      expect(subject).not_to include(failed_contribution)
    end

    it 'does not return contributions scheduled outside the range' do
      expect(subject).not_to include(future_contribution)
    end
  end
end
