require 'rails_helper'

RSpec.describe Payments::GetActivePaymentMethod, type: :query do
  let(:donor) { create(:donor) }
  let(:service) { described_class.new }

  describe '#call' do
    subject { service.call(donor: donor) }

    context 'when there is an active payment method' do
      let!(:active_payment_method) { create(:payment_method, donor: donor, deactivated_at: nil) }

      it 'returns the active payment method' do
        expect(subject).to eq(active_payment_method)
      end
    end

    context 'when there are multiple active payment methods' do
      let!(:active_payment_method1) { create(:payment_method, donor: donor, deactivated_at: nil) }
      let!(:active_payment_method2) { create(:payment_method, donor: donor, deactivated_at: nil) }

      it 'returns the first active payment method' do
        expect(subject).to eq(active_payment_method1)
      end
    end

    context 'when there is no active payment method' do
      let!(:inactive_payment_method) { create(:payment_method, donor: donor, deactivated_at: Time.current) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the donor has no payment methods' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
