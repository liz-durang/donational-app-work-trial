require 'rails_helper'

RSpec.describe 'DELETE /partners/:partner_id/donors/:id', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:donor_to_delete) { create(:donor) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor_to_delete.id).and_return(donor_to_delete)
  end

  context 'when the donor has permission' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
      allow(Donors::DeactivateDonor).to receive(:run).and_return(successful_outcome)
    end

    it 'deletes the donor and redirects to the partner donors path' do
      delete partner_donor_path(partner_id: partner.id, id: donor_to_delete.id)
      expect(response).to redirect_to(partner_donors_path(partner))
      expect(flash[:success]).to eq('Donor deleted successfully')
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not delete the donor and redirects to the new partner donor path with error' do
      delete partner_donor_path(partner_id: partner.id, id: donor_to_delete.id)
      expect(response).to redirect_to(new_partner_donor_path(partner))
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a donor for this partner.")
    end
  end

  context 'when donor deletion fails' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
      allow(Donors::DeactivateDonor).to receive(:run).and_return(failure_outcome)
    end

    it 'does not delete the donor and redirects to the edit partner donor path with error' do
      delete partner_donor_path(partner_id: partner.id, id: donor_to_delete.id)
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor_to_delete))
      expect(flash[:error]).to eq('Error message')
    end
  end
end
