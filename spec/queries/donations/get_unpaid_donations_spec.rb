require 'rails_helper'

RSpec.describe Donations::GetUnpaidDonations do
  let(:organization) { create(:organization) }

  subject { Donations::GetUnpaidDonations.call(organization: organization) }

  context 'when there are no donations for the organization' do
    let(:other_organization) { create(:organization) }
    before { create(:donation, organization: other_organization, grant: nil) }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context "when all of the organization's donations have been paid" do
    let(:grant) { create(:grant) }
    before do
      create(:donation, organization: organization, grant: grant)
      create(:donation, organization: organization, grant: grant)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there is an unpaid donation' do
    let!(:unpaid_donation) do
      create(:donation, organization: organization, grant: nil)
    end

    it 'returns the active allocation' do
      expect(subject).to be_a ActiveRecord::Relation
      expect(subject).to eq [unpaid_donation]
    end
  end
end
