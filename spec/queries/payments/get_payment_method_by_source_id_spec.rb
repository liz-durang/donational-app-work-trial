require 'rails_helper'

RSpec.describe Payments::GetPaymentMethodBySourceId, type: :query do
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call(source_id: source_id) }

    context 'when a payment method with the given source_id exists' do
      let(:source_id) { 'test_source_id' }
      let!(:payment_method) { create(:payment_method, payment_processor_source_id: source_id) }

      it 'returns the payment method' do
        expect(subject).to eq(payment_method)
      end
    end

    context 'when no payment method with the given source_id exists' do
      let(:source_id) { 'non_existent_source_id' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the source_id is nil' do
      let(:source_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
