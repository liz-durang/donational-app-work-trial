require 'rails_helper'

RSpec.describe Donations::DeleteDonationsForContribution do
  let(:contribution) { create(:contribution) }
  let(:contribution2) { create(:contribution) }
  before do
    create(:donation, contribution: contribution)
    create(:donation, contribution: contribution)
    create(:donation, contribution: contribution2)
    create(:donation, contribution: contribution2)
  end

  it 'deletes only the donations associated with the contribution' do
    command = described_class.run(contribution: contribution)
    expect(Contribution.count).to eq 2
  end
end
