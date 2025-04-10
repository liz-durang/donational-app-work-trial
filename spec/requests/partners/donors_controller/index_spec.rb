require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/donors', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:donors) { create_list(:donor, 3, partners: [partner]) }
  let(:paginated_donors) { Kaminari.paginate_array(donors).page(1) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(Partners::ListDonors).to receive(:call).with(search: nil, partner: partner, page: nil).and_return(paginated_donors)
  end

  context 'when the donor has permission' do
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
    end

    it 'returns a successful response' do
      get partner_donors_path(partner_id: partner.id)
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      get partner_donors_path(partner_id: partner.id)
      expect(response).to render_template(:index)
    end

    it 'assigns the correct view model' do
      get partner_donors_path(partner_id: partner.id)
      expect(assigns(:view_model).partner).to eq(partner)
      expect(assigns(:view_model).donors).to eq(paginated_donors)
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'redirects to the new partner donor path with error' do
      get partner_donors_path(partner_id: partner.id)
      expect(response).to redirect_to(new_partner_donor_path(partner))
      expect(flash[:error]).to eq("Sorry, you don't have permission to create a donor for this partner.")
    end
  end
end
