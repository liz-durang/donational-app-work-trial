require 'rails_helper'

RSpec.describe Grants::ProcessGrant do
  include ActiveSupport::Testing::TimeHelpers

  context 'when the Grant has already been processed' do
    let(:grant) { create(:grant, processed_at: 1.day.ago) }

    it 'does not process any payments' do
      expect(Grants::SendCheck).not_to receive(:run)

      command = Grants::ProcessGrant.run(grant: grant)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(grant: :already_processed)
    end
  end

  context 'when the Grant has not been processed' do
    let(:organization) { create(:organization) }
    let(:grant) do
      create(:grant, organization: organization, amount_cents: 123, processed_at: nil)
    end
    let(:successful_command) { double(success?: true)}

    around do |spec|
      travel_to(Time.now) do
        spec.run
      end
    end

    it "sends a check to the organization and persists the processed at time" do
      expect(Grants::SendCheck)
        .to receive(:run)
        .with(organization: organization, amount_cents: 123)
        .and_return(successful_command)

      command = Grants::ProcessGrant.run(grant: grant)

      expect(command).to be_success
      expect(grant.reload.processed_at).to eq Time.zone.now
    end
  end
end
