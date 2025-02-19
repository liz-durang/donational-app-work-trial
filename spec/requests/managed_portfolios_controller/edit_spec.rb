require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/managed_portfolios/:id/edit', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:managed_portfolio) { create(:managed_portfolio, partner: partner) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:managed_portfolio).and_return(managed_portfolio)
  end

  context 'when the donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    it 'returns a successful response' do
      get edit_partner_managed_portfolio_path(partner, managed_portfolio)
      expect(response).to have_http_status(:success)
    end

    it 'renders the edit template' do
      get edit_partner_managed_portfolio_path(partner, managed_portfolio)
      expect(response).to render_template(:edit)
    end

    it 'assigns the correct view model' do
      get edit_partner_managed_portfolio_path(partner, managed_portfolio)
      expect(assigns(:view_model).partner).to eq(partner)
      expect(assigns(:view_model).managed_portfolio).to eq(managed_portfolio)
      expect(assigns(:view_model).image).to eq(managed_portfolio.image)
      expect(assigns(:view_model).managed_portfolio_path).to eq(partner_managed_portfolio_path)
    end
  end
end
