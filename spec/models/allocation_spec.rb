require 'rails_helper'

RSpec.describe Allocation, type: :model do
  describe '#active?' do
    context 'when it has a deactivated_at timestamp' do
      it 'is false' do
        allocation = Allocation.new(deactivated_at: 1.day.ago)
        expect(allocation.active?).to be false
      end
    end

    context 'when it does not have a deactivated_at timestamp' do
      it 'is true' do
        allocation = Allocation.new(deactivated_at: nil)
        expect(allocation.active?).to be true
      end
    end
  end
end
