require 'rails_helper'

RSpec.describe Donations::DeleteUngrantedDonationsForContribution do
  let(:contribution) { create(:contribution) }
  let(:contribution2) { create(:contribution) }

  before do
    create(:donation, contribution: contribution)
    create(:donation, contribution: contribution)
    create(:donation, contribution: contribution, grant: create(:grant))
    create(:donation, contribution: contribution2)
  end

  it 'deletes only the donations associated with the contribution that are ungranted' do
    expect { described_class.run(contribution: contribution) }
      .to change(Donation, :count)
      .by(-2)
  end
end
