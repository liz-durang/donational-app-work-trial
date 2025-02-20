require 'rails_helper'

RSpec.describe Contributions::GetUnprocessedFailedContributions, type: :query do
  let(:donor) { create(:donor) }
  let(:donor2) { create(:donor) }
  let!(:payment_method1) { create(:payment_method, donor: donor, deactivated_at: nil, retry_count: 1) }
  let!(:unprocessed_failed_contribution1) { create(:contribution, donor: donor, processed_at: nil, failed_at: 1.day.ago) }
  let!(:unprocessed_failed_contribution2) { create(:contribution, donor: donor, processed_at: nil, failed_at: 2.days.ago + 1.hour) }
  let!(:processed_contribution) { create(:contribution, donor: donor, processed_at: 1.day.ago, failed_at: 1.day.ago) }
  let!(:unprocessed_non_failed_contribution) { create(:contribution, donor: donor, processed_at: nil, failed_at: nil) }
  let!(:unprocessed_failed_contribution_outside_range) { create(:contribution, donor: donor, processed_at: nil, failed_at: 3.days.ago) }
  let!(:unprocessed_failed_contribution_with_deactivated_payment_method) { create(:contribution, donor: donor2, processed_at: nil, failed_at: 1.day.ago) }
  let!(:deactivated_payment_method) { create(:payment_method, donor: donor2, deactivated_at: 1.day.ago, retry_count: 1) }

  describe '#call' do
    subject { described_class.call(failed_after: 2.days.ago, failed_before: Time.now) }

    it 'returns unprocessed failed contributions within the failed range' do
      # expect(subject.count).to eq(2)
      expect(subject.pluck(:id)).to match_array([
        unprocessed_failed_contribution1.id, 
        unprocessed_failed_contribution2.id,
      ])
    end

    it 'does not return processed contributions' do
      expect(subject).not_to include(processed_contribution)
    end

    it 'does not return unprocessed non-failed contributions' do
      expect(subject).not_to include(unprocessed_non_failed_contribution)
    end

    it 'does not return unprocessed failed contributions outside the failed range' do
      expect(subject).not_to include(unprocessed_failed_contribution_outside_range)
    end

    it 'does not return unprocessed failed contributions with deactivated payment methods' do
      expect(subject).not_to include(unprocessed_failed_contribution_with_deactivated_payment_method)
    end
  end
end
