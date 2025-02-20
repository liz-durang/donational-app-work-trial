require 'rails_helper'

RSpec.describe Contributions::GetTargetContributionAmountCents, type: :query do
  let(:donor) { create(:donor, annual_income_cents: 120_000_00, donation_rate: 0.1) }

  describe '#call' do
    subject { described_class.new.call(donor: donor, frequency: frequency) }

    context 'when frequency is annually' do
      let(:frequency) { 'annually' }

      it 'returns the target annual amount in cents' do
        expect(subject).to eq(12_000_00)
      end
    end

    context 'when frequency is quarterly' do
      let(:frequency) { 'quarterly' }

      it 'returns the target quarterly amount in cents' do
        expect(subject).to eq(3_000_00)
      end
    end

    context 'when frequency is monthly' do
      let(:frequency) { 'monthly' }

      it 'returns the target monthly amount in cents' do
        expect(subject).to eq(1_000_00)
      end
    end

    context 'when frequency is once' do
      let(:frequency) { 'once' }

      it 'returns the target monthly amount in cents' do
        expect(subject).to eq(1_000_00)
      end
    end

    context 'when frequency is invalid' do
      let(:frequency) { 'weekly' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when donor has no annual income' do
      let(:donor) { create(:donor, annual_income_cents: nil, donation_rate: 0.1) }
      let(:frequency) { 'annually' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when donor has no donation rate' do
      let(:donor) { create(:donor, annual_income_cents: 120_000_00, donation_rate: nil) }
      let(:frequency) { 'annually' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
