require 'rails_helper'

RSpec.describe Donations::GetUnpaidDonations do
  let(:organization) { create(:organization) }

  subject { Donations::GetUnpaidDonations.call }

  context 'when there are no unpaid donations' do
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
      expect(subject).to be_a Hash
      expect(subject).to eq ({ organization => [unpaid_donation] })
    end
  end
end
