require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/donors/:id/edit', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:subscription) { create(:subscription, donor:) }
  let(:payment_method) { create(:payment_method, donor:) }
  let(:contributions) { create_list(:contribution, 3, donor:, partner:) }
  let(:partner_affiliation) { create(:partner_affiliation, donor:, partner:) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(Contributions::GetActiveSubscription).to receive(:call).with(donor:).and_return(subscription)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor:).and_return(payment_method)
    allow(Contributions::GetContributions).to receive(:call).with(donor:).and_return(contributions)
    allow(Partners::GetPartnerAffiliationByDonor).to receive(:call).with(donor:).and_return(partner_affiliation)
  end

  context 'when the donor has permission' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
    end

    it 'returns a successful response' do
      get edit_partner_donor_path(partner_id: partner.id, id: donor.id)
      expect(response).to have_http_status(:success)
    end

    it 'renders the edit template' do
      get edit_partner_donor_path(partner_id: partner.id, id: donor.id)
      expect(response).to render_template(:edit)
    end

    it 'assigns the correct view model' do
      get edit_partner_donor_path(partner_id: partner.id, id: donor.id)
      expect(assigns(:view_model).partner).to eq(partner)
      expect(assigns(:view_model).donor).to eq(donor)
      expect(assigns(:view_model).subscription).to eq(subscription)
      expect(assigns(:view_model).payment_method).to eq(payment_method)
      expect(assigns(:view_model).contributions).to eq(contributions)
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'redirects to the new partner donor path with error' do
      get edit_partner_donor_path(partner_id: partner.id, id: donor.id)
      expect(response).to redirect_to(new_partner_donor_path(partner))
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a donor for this partner.")
    end
  end
end
