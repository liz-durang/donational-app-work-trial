require 'rails_helper'

RSpec.describe Donation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:portfolio) }
    it { is_expected.to belong_to(:organization).with_foreign_key('organization_ein') }
    it { is_expected.to belong_to(:allocation).optional(true) }
    it { is_expected.to belong_to(:contribution) }
    it { is_expected.to belong_to(:grant).optional(true) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:donor).to(:contribution) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:contribution) }
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_presence_of(:portfolio) }
  end

  describe "scopes" do
    let!(:unpaid) { create(:donation, grant: nil) }
    let!(:paid) { create(:donation, grant: create(:grant)) } 

    describe ".unpaid" do
      it "returns donations without a grant" do
        expect(described_class.unpaid).to eq([unpaid])
      end
    end

    describe ".paid" do
      it "returns donations with a grant" do
        expect(described_class.paid).to eq([paid])
      end
    end
  end

  describe "monetize" do
    describe "#amount_cents" do
      let(:donation) { build(:donation, amount_cents: 5000) }
      it "monetizes the amount_cents attribute to a Money object" do
        expect(donation.amount).to be_a(Money)
    
        expect(donation.amount).to eq(Money.new(5000))
      end
    end
  end
end
