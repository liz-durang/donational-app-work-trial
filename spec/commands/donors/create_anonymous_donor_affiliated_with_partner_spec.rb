require 'rails_helper'

RSpec.describe Donors::CreateAnonymousDonorAffiliatedWithPartner do
  let!(:default_partner) { create(:partner, name: Partner::DEFAULT_PARTNER_NAME) }
  let!(:partner) { create(:partner) }
  let!(:uuid) { SecureRandom.uuid }

  it "creates a donor with a prespecified id" do
    expect(Donors::CreateAnonymousDonorAffiliatedWithPartner.run(donor_id: uuid).result.id).to eq uuid
  end

  it "affiliates the donor with default partner" do
    command = Donors::CreateAnonymousDonorAffiliatedWithPartner.run(donor_id: uuid)

    expect(Partners::GetPartnerForDonor.call(donor: command.result)).to eq default_partner
  end

  it "affiliates the donor with the prespecified partner" do
    command = Donors::CreateAnonymousDonorAffiliatedWithPartner.run(donor_id: uuid, partner: partner)

    expect(Partners::GetPartnerForDonor.call(donor: command.result)).to eq partner
  end

  it "creates a donor with a unique random id if none is provided" do
    first_id = Donors::CreateAnonymousDonorAffiliatedWithPartner.run.result.id
    second_id = Donors::CreateAnonymousDonorAffiliatedWithPartner.run.result.id

    expect(first_id).not_to eq second_id
  end
end
