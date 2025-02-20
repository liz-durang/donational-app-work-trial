require 'rails_helper'

RSpec.describe Constants::GetLocalizedPaymentMethods, type: :query do
  describe '#call' do
    subject { described_class.new.call }

    it 'returns the correct payment methods for GBP' do
      expect(subject[:GBP]).to eq([PaymentMethods::BacsDebit, PaymentMethods::Card])
    end

    it 'returns the correct payment methods for CAD' do
      expect(subject[:CAD]).to eq([PaymentMethods::AcssDebit, PaymentMethods::Card])
    end

    it 'returns the correct payment methods for AUD' do
      expect(subject[:AUD]).to eq([PaymentMethods::Card])
    end

    it 'returns the correct payment methods for USD' do
      expect(subject[:USD]).to eq([PaymentMethods::BankAccount, PaymentMethods::Card])
    end

    it 'returns a hash with indifferent access' do
      expect(subject).to be_a(HashWithIndifferentAccess)
    end

    it 'returns a frozen hash' do
      expect(subject).to be_frozen
    end
  end
end
