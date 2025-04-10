require 'rails_helper'

RSpec.describe Payments::GetPaymentProcessorAccountId, type: :query do
  let(:donor) { create(:donor) }
  let(:service) { described_class.new }
  let(:partner) { double('Partner', payment_processor_account_id: 'test_account_id') }

  describe '#call' do
    subject { service.call(donor: donor) }

    context 'when the partner is found' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(partner)
      end

      it 'returns the payment processor account id' do
        expect(subject).to eq('test_account_id')
      end
    end

    context 'when the partner is not found' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(nil)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when an error occurs' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_raise(StandardError.new('error'))
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError, 'error')
      end
    end
  end
end
