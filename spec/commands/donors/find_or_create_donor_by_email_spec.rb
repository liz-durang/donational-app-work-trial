require 'rails_helper'

RSpec.describe Donors::FindOrCreateDonorByEmail do
  subject do
    Donors::FindOrCreateDonorByEmail.run(email: email, partner: partner, first_name: first_name, last_name: last_name)
  end

  let(:email) { 'donny@donator.com' }
  let(:first_name) { 'Donny' }
  let(:last_name) { 'Donator' }
  let(:partner) { create(:partner) }
  let(:donor) { Donor.find_by(email: email) }

  context 'when first_name, last_name and entity_name are not provided' do
    let(:first_name) { nil }
    let(:last_name) { nil }

    it 'does not create the donor' do
      command = Donors::FindOrCreateDonorByEmail.run(email: email, partner: partner, first_name: first_name, last_name: last_name)
      expect(command).not_to be_success
      expect(command.errors.message_list[0]).to eq('Either entity_name or first_name and last_name should be present')
    end
  end

  context 'when the email does not exist' do
    it 'creates the donor' do
      expect { subject }.to change { Donor.count }.from(0).to(1)

      expect(Partners::GetPartnerForDonor.call(donor: donor)).to eq partner
    end

    it 'affiliates the donor with the partner' do
      expect { subject }.to change { PartnerAffiliation.count }.from(0).to(1)

      expect(Partners::GetPartnerAffiliationByDonorAndPartner.call(donor: donor, partner: partner).present?).to be true
    end
  end

  context 'when the email already exists' do
    let(:first_name) { 'John' }
    let(:last_name) { 'Donator' }
    let!(:donor) { create(:donor, email: email) }

    context 'and the donor is already affiliated with the partner' do
      let!(:affiliation) do
        create(:partner_affiliation, donor: donor, partner: partner)
      end

      it 'does not create the affiliation' do
        expect { subject }.not_to(change { PartnerAffiliation.count })

        expect(Partners::GetPartnerForDonor.call(donor: donor)).to eq partner
      end

      it 'updates donor name' do
        command = Donors::FindOrCreateDonorByEmail.run(email: email, partner: partner, first_name: first_name, last_name: last_name)
        expect(command).to be_success
        expect(command.result.first_name).to eq first_name
        expect(command.result.last_name).to eq last_name
      end
    end

    context 'and the donor is not affiliated with the partner' do
      it 'fails with error' do
        command = Donors::FindOrCreateDonorByEmail.run(email: email, partner: partner, first_name: first_name, last_name: last_name)
        expect(command).not_to be_success
        expect(command.errors.message_list[0]).to eq('The email is already in use')
      end
    end
  end
end
