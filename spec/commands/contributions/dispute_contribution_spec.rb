# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::DisputeContribution do
  let(:contribution) { create(:contribution) }

  it 'marks the contribution as disputed and deletes the donations' do
    expect(Donations::DeleteUngrantedDonationsForContribution).to receive(:run).with(
      contribution: contribution
    ).and_return(double(success?: true))

    command = described_class.run(contribution_id: contribution.id)

    expect(command).to be_success
    contribution.reload
    expect(contribution).to be_disputed
    expect(contribution.disputed_at).to be_present
  end
end
