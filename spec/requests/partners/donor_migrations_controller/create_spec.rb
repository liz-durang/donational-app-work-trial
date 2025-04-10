require 'rails_helper'

RSpec.describe 'POST /partners/:source_partner_id/donor_migrations', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:source_partner) { create(:partner) }
  let(:destination_partner) { create(:partner) }
  let(:migration_params) do
    {
      donor_id: donor.id,
      source_partner_id: source_partner.id,
      destination_partner_id: destination_partner.id
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: source_partner.id).and_return(source_partner)
    allow(Partners::GetPartnerById).to receive(:call).with(id: destination_partner.id).and_return(destination_partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
  end

  context 'when the donor has permission' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: source_partner.id).and_return(true)
      allow(donor.partners).to receive(:exists?).with(id: destination_partner.id).and_return(true)
    end

    it 'migrates the donor and redirects to the edit destination partner donor path' do
      post partner_donor_migrations_path(partner_id: source_partner.id), params: migration_params
      expect(response).to redirect_to(edit_partner_donor_path(destination_partner, donor))
      expect(flash[:success]).to eq("Donor Migrated Successfully")
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: source_partner.id))
      allow(donor.partners).to receive(:exists?).with(id: source_partner.id).and_return(false)
      allow(donor.partners).to receive(:exists?).with(id: destination_partner.id).and_return(false)
    end

    it 'does not migrate the donor and redirects to the edit source partner donor path with error' do
      post partner_donor_migrations_path(partner_id: source_partner.id), params: migration_params
      expect(response).to redirect_to(edit_partner_donor_path(source_partner, donor))
      expect(flash[:error]).to eq("Sorry, you don't have permission to migrate donors for this partner.")
    end
  end
end
