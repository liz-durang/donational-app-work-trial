require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/reports', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let!(:partner_donor) { create(:donor) }
  let!(:partner) { create(:partner, donors: [partner_donor]) }

  before do
    login_as(partner_donor)
  end

  context 'when the donor has permission' do
    it 'returns a successful response' do
      get partner_reports_path(partner)
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      get partner_reports_path(partner)
      expect(response).to render_template(:index)
    end

    it 'assigns the correct view model' do
      get partner_reports_path(partner)
      expect(assigns(:view_model).partner).to eq(partner)
    end
  end

  context 'when the donor does not have permission' do
    let!(:other_donor) { create(:donor) }

    before do
      login_as(other_donor)
    end

    it 'redirects to the edit partner path' do
      get partner_reports_path(partner)
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash error message' do
      get partner_reports_path(partner)
      expect(flash[:error]).to eq("Sorry, you don't have permission to export data from this partner account")
    end
  end
end
