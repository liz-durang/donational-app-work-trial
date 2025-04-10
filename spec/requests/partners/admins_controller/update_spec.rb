require 'rails_helper'

RSpec.describe 'PUT /partners/:partner_id/admins/:id', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }

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

    it 'revokes admin privileges and redirects to edit partner donor path' do
      put partner_admin_path(partner_id: partner.id, id: donor.id), params: { donor_id: donor.id }
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:success]).to eq("Admin Privileges Revoked")
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not revoke admin privileges and redirects to edit partner donor path with error' do
      put partner_admin_path(partner_id: partner.id, id: donor.id), params: { donor_id: donor.id }
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:error]).to eq("Sorry, you don't have permission to grant admin privileges for this partner.")
    end
  end
end
