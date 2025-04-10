require 'rails_helper'

RSpec.describe 'POST /partners/:partner_id/donors', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:donor_params) do
    {
      email: 'test@example.com',
      first_name: 'Test',
      last_name: 'User',
      title: 'Mr.',
      house_name_or_number: '123',
      postcode: 'AA1 3DD',
      uk_gift_aid_accepted: true
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
  end

  context 'when the donor has permission' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
    end

    context 'when all required fields are filled' do
      before do
        allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(successful_outcome)
        allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(successful_outcome)
      end

      it 'creates a donor and redirects to the partner donors path' do
        post partner_donors_path(partner_id: partner.id), params: donor_params
        expect(response).to redirect_to(partner_donors_path(partner))
        expect(flash[:success]).to eq('Donor Created Successfully')
      end
    end

    context 'when required fields are left blank' do
      let(:invalid_donor_params) { donor_params.merge(email: '') }

      it 'does not create a donor and redirects to the new partner donor path with error' do
        post partner_donors_path(partner_id: partner.id), params: invalid_donor_params
        expect(response).to redirect_to(new_partner_donor_path(partner))
        expect(flash[:error]).to include('Please fill in the required field(s)')
      end
    end

    context 'when donor creation fails' do
      before do
        allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(failure_outcome)
      end

      it 'does not create a donor and redirects to the partner donors path with error' do
        post partner_donors_path(partner_id: partner.id), params: donor_params
        expect(response).to redirect_to(partner_donors_path(partner))
        expect(flash[:error]).to eq('Error message')
      end
    end

    context 'when updating custom donor information fails' do
      before do
        allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(successful_outcome(create(:donor)))
        allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(failure_outcome)
      end

      it 'creates a donor but shows an error message' do
        post partner_donors_path(partner_id: partner.id), params: donor_params
        expect(response).to redirect_to(partner_donors_path(partner))
        expect(flash[:error]).to eq('Error message')
      end
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not create a donor and redirects to the new partner donor path with error' do
      post partner_donors_path(partner_id: partner.id), params: donor_params
      expect(response).to redirect_to(new_partner_donor_path(partner))
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a donor for this partner.")
    end
  end
end
