require 'rails_helper'

RSpec.describe Donors::CreateDonorAffiliatedWithPartner do
  subject do
    Donors::CreateDonorAffiliatedWithPartner.run(email: email, partner: partner, first_name: first_name, last_name: last_name)
  end

  let(:email) { 'donny@donator.com' }
  let(:first_name) { 'Donny' }
  let(:last_name) { 'Donator' }
  let(:partner) { create(:partner) }
  let(:donor) { Donor.find_by(email: email) }

  it 'creates the donor' do
    command = Donors::CreateDonorAffiliatedWithPartner.run(email: email, partner: partner, first_name: first_name, last_name: last_name)

    expect(command).to be_success
  end

  it 'affiliates the donor with the partner' do
    expect { subject }.to change { PartnerAffiliation.count }.from(0).to(1)

    expect(Partners::GetPartnerAffiliationByDonorAndPartner.call(donor: donor, partner: partner).present?).to be true
  end

  context 'when first name, last name and entity name are not provided' do
    let(:first_name) { nil }
    let(:last_name) { nil }

    it 'does not create the donor' do
      command = Donors::CreateDonorAffiliatedWithPartner.run(email: email, partner: partner, first_name: first_name, last_name: last_name)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(donor: :invalid_name)
    end
  end

  context 'when the email has already been taken' do
    let(:first_name) { 'John' }
    let(:last_name) { 'Donator' }
    let!(:donor) { create(:donor, email: email) }

    it 'fails with error' do
      command = Donors::CreateDonorAffiliatedWithPartner.run(email: email, partner: partner, first_name: first_name, last_name: last_name)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(donor: :email_already_used)
    end
  end
end
