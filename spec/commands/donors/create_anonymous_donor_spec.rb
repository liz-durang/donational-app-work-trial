require 'rails_helper'

RSpec.describe Donors::CreateAnonymousDonor do
  let!(:uuid) { SecureRandom.uuid }

  it "creates a donor with a prespecified id" do
    expect(Donors::CreateAnonymousDonor.run(donor_id: uuid).result.id).to eq uuid
  end

  it "creates a donor with a unique random id if none is provided" do
    first_id = Donors::CreateAnonymousDonor.run.result.id
    second_id = Donors::CreateAnonymousDonor.run.result.id
    expect(first_id).not_to eq second_id
  end
end
