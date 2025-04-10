require 'rails_helper'

RSpec.describe 'PUT /partners/:partner_id/donors/:id', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:donor_params) do
    {
      email: 'updated@example.com',
      first_name: 'Updated',
      last_name: 'User',
      title: 'Dr.',
      house_name_or_number: '456',
      postcode: 'BB2 4EE',
      uk_gift_aid_accepted: false
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
        allow(Donors::UpdateDonor).to receive(:run).and_return(successful_outcome)
        allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(successful_outcome)
      end

      it 'updates the donor and redirects to the edit partner donor path' do
        put partner_donor_path(partner_id: partner.id, id: donor.id), params: donor_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:success]).to eq('Donor Updated Successfully')
      end
    end

    context 'when required fields are left blank' do
      let(:invalid_donor_params) { donor_params.merge(email: '') }

      it 'does not update the donor and redirects to the edit partner donor path with error' do
        put partner_donor_path(partner_id: partner.id, id: donor.id), params: invalid_donor_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:error]).to include('Please fill in the required field(s)')
      end
    end

    context 'when donor update fails' do
      before do
        allow(Donors::UpdateDonor).to receive(:run).and_return(failure_outcome)
      end

      it 'does not update the donor and redirects to the edit partner donor path with error' do
        put partner_donor_path(partner_id: partner.id, id: donor.id), params: donor_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:error]).to eq('Error message')
      end
    end

    context 'when updating custom donor information fails' do
      before do
        allow(Donors::UpdateDonor).to receive(:run).and_return(successful_outcome)
        allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(failure_outcome)
      end

      it 'updates the donor but shows an error message' do
        put partner_donor_path(partner_id: partner.id, id: donor.id), params: donor_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:error]).to eq('Error message')
      end
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not update the donor and redirects to the new partner donor path with error' do
      put partner_donor_path(partner_id: partner.id, id: donor.id), params: donor_params
      expect(response).to redirect_to(new_partner_donor_path(partner))
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a donor for this partner.")
    end
  end
end
