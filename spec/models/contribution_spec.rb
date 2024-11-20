require 'rails_helper'

RSpec.describe Contribution, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:portfolio) }
    it { is_expected.to belong_to(:donor) }
    it { is_expected.to belong_to(:partner) }
    it { is_expected.to have_many(:donations) }
    it { is_expected.to have_many(:organizations).through(:donations) }
  end

  describe "enums" do
    describe "payment_status" do
      it "has payment statuses defined" do
        expect(Contribution.payment_statuses).to eq({
          "unprocessed" => "unprocessed",
          "pending" => "pending",
          "succeeded" => "succeeded",
          "failed" => "failed",
          "refunded" => "refunded",
          "disputed" => "disputed"
        })
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_currency) }

    describe "#external_reference_id" do
      let(:partner) { create(:partner)}
      it 'validates uniqueness of external_reference_id scoped to partner' do
        create(:contribution, partner: partner, external_reference_id: '12345')
  
        duplicate_contribution = build(:contribution, partner: partner, external_reference_id: '12345')
        expect(duplicate_contribution).not_to be_valid
        expect(duplicate_contribution.errors[:external_reference_id]).to include('has already been taken')
      end
  
      it 'allows nil external_reference_id' do
        create(:contribution, partner: partner, external_reference_id: nil)
  
        contribution_with_nil = build(:contribution, partner: partner, external_reference_id: nil)
        expect(contribution_with_nil).to be_valid
      end
  
      it 'allows duplicate external_reference_id for different partners' do
        another_partner = create(:partner)
        create(:contribution, partner: partner, external_reference_id: '12345')
  
        contribution_with_different_partner = build(:contribution, partner: another_partner, external_reference_id: '12345')
        expect(contribution_with_different_partner).to be_valid
      end
    end
  end

  describe "delegations" do
    let!(:donor) { create(:donor) }
    let!(:contribution) { create(:contribution, donor: donor) }

    describe "#donor_name" do
      it "is delegated to donor" do
        expect(contribution.donor_name).to eq(donor.name)
      end
    end

    describe "#donor_email" do
      it "is delegated to donor" do
        expect(contribution.donor_email).to eq(donor.email)
      end
    end
  end

  describe "methods" do
    let(:contribution) { create(:contribution, amount_cents: 1000, tips_cents: 100) }

    describe "#amount_dollars" do
      it "returns the amount in dollars" do
        expect(contribution.amount_dollars).to eq(10.0)
      end
    end

    describe "#total_charges_cents" do
      it "returns total charges in cents" do
        expect(contribution.total_charges_cents).to eq(1100)
      end
    end
  end
end
