require 'rails_helper'

RSpec.describe Grant, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).with_foreign_key('organization_ein') }
    it { is_expected.to have_many(:donations) }
  end

  describe "monetize" do
    let(:grant) { build(:grant, amount_cents: 10000) }

    describe "#amount_cents" do
      it 'returns the amount cents' do
        expect(grant.amount_cents).to eq(10000)
      end
    end

    describe "#amount" do
      it 'returns money object' do
        expect(grant.amount).to eq(Money.new(10000))
      end
    end
  end

  describe 'methods' do
    describe '#to_param' do
      let!(:grant) { create(:grant) }

      it 'returns the short_id' do
        expect(grant.to_param).to eq(grant.short_id)
      end
    end

    describe '#short_id' do
      let!(:grant) { create(:grant) }

      it 'returns a shorter id' do
        expect(grant.short_id).to eq(grant.id[0...6])
      end
    end
  end
end
