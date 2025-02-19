require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/managed_portfolios/new', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
  end

  context 'when the donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    it 'returns a successful response' do
      get new_partner_managed_portfolio_path(partner)
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get new_partner_managed_portfolio_path(partner)
      expect(response).to render_template(:new)
    end

    it 'assigns the correct view model' do
      get new_partner_managed_portfolio_path(partner)
      expect(assigns(:view_model).partner).to eq(partner)
    end
  end
end
