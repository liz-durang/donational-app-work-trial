require 'rails_helper'

RSpec.describe Grants::VoidGrant do
  include ActiveSupport::Testing::TimeHelpers

  around do |spec|
    travel_to(Time.now) do
      spec.run
    end
  end

  context 'when the Grant has already been processed' do
    let(:grant) { create(:grant, processed_at: 1.day.ago) }

    it 'marks the grant as voided' do
      command = Grants::VoidGrant.run(grant: grant)

      expect(command).to be_success
      expect(grant.reload.processed_at).to eq 1.day.ago
      expect(grant.reload.voided_at).to eq Time.zone.now
    end

    it 'marks any donations connected to this grant as unpaid' do
      donation_1 = create(:donation, grant: grant)
      donation_2 = create(:donation, grant: grant)

      command = Grants::VoidGrant.run(grant: grant)

      expect(command).to be_success
      expect(grant.reload.processed_at).to eq 1.day.ago
      expect(donation_1.reload.grant).to be nil
      expect(donation_2.reload.grant).to be nil
    end
  end


  context 'when the Grant has not been processed' do
    let(:grant) { create(:grant, processed_at: nil) }

    it "marks the grant and voided and processed at the current time" do
      command = Grants::VoidGrant.run(grant: grant)

      expect(command).to be_success
      expect(grant.reload.processed_at).to eq Time.zone.now
      expect(grant.reload.voided_at).to eq Time.zone.now
    end
  end
end
