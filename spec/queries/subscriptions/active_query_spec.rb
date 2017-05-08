require 'rails_helper'

RSpec.describe Subscriptions::ActiveQuery do
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  context 'when there are no subscriptions for the donor' do
    before { create(:subscription, donor: other_donor) }

    it 'returns nil' do
      expect(Subscriptions::ActiveQuery.call(donor: donor)).to be_nil
    end
  end

  context "when all of the donor's subscriptions have been deactivated" do
    before do
      create(:subscription, donor: donor, deactivated_at: 2.days.ago)
      create(:subscription, donor: donor, deactivated_at: 1.day.ago)
    end

    it 'returns nil' do
      expect(Subscriptions::ActiveQuery.call(donor: donor)).to be_nil
    end
  end

  context 'when there is an existing active subscriptions' do
    before do
      create(:subscription, donor: donor, deactivated_at: 2.days.ago)
      create(:subscription, donor: donor, deactivated_at: 1.day.ago)
    end

    let!(:subscription) do
      create(:subscription, donor: donor, deactivated_at: nil)
    end

    it 'returns the active subscription' do
      expect(Subscriptions::ActiveQuery.call(donor: donor)).to eq subscription
    end
  end
end
