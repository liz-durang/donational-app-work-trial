require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe '#active?' do
    context 'when it has a deactivated_at timestamp' do
      it 'is false' do
        subscription = Subscription.new(deactivated_at: 1.day.ago)
        expect(subscription.active?).to be false
      end
    end

    context 'when it does not have a deactivated_at timestamp' do
      it 'is true' do
        subscription = Subscription.new(deactivated_at: nil)
        expect(subscription.active?).to be true
      end
    end
  end
end
