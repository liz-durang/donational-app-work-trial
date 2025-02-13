require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe 'associations' do
    it { should belong_to(:donor) }
  end

  describe 'methods' do
    describe '#retry_count_limit_reached?' do
      let(:payment_method) { build(:payment_method, retry_count: retry_count) }

      context 'when retry_count is 3' do
        let(:retry_count) { 3 }

        it 'returns true' do
          expect(payment_method.retry_count_limit_reached?).to be true
        end
      end

      context 'when retry_count is not 3' do
        let(:retry_count) { 2 }

        it 'returns false' do
          expect(payment_method.retry_count_limit_reached?).to be false
        end
      end
    end

    describe '#payment_type' do
      let(:payment_method) { build(:payment_method, type: 'PaymentMethods::Card') }

      it 'returns the demodulized type' do
        expect(payment_method.payment_type).to eq('Card')
      end
    end
  end
end
