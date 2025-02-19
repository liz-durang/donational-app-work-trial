require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/managed_portfolios', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:active_managed_portfolios) { create_list(:managed_portfolio, 3, partner: partner) }
  let(:archived_managed_portfolios) { create_list(:managed_portfolio, 2, partner: partner, hidden_at: DateTime.current) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:active_managed_portfolios).and_return(active_managed_portfolios)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:archived_managed_portfolios).and_return(archived_managed_portfolios)
  end

  context 'with donor having permission' do
    before do
      allow_any_instance_of(ManagedPortfoliosController).to receive(:ensure_donor_has_permission!).and_return(true) 
    end

    it 'returns a successful response' do
      get partner_managed_portfolios_path(partner)
      expect(response).to have_http_status(:success)
    end
  
    it 'renders the index template' do
      get partner_managed_portfolios_path(partner)
      expect(response).to render_template(:index)
    end
  
    it 'assigns the correct view model' do
      get partner_managed_portfolios_path(partner)
      expect(assigns(:view_model).partner).to eq(partner)
      expect(assigns(:view_model).active_managed_portfolios).to eq(active_managed_portfolios)
      expect(assigns(:view_model).archived_managed_portfolios).to eq(archived_managed_portfolios)
    end
  end
  

  describe '#ensure_donor_has_permission!' do
    context 'when the donor does not have permission' do
      before do
        allow(donor).to receive_message_chain(:partners, :exists?).and_return(false)
      end

      it 'redirects to the new_partner_managed_portfolio_path' do
        get partner_managed_portfolios_path(partner)
        expect(response).to redirect_to(new_partner_managed_portfolio_path(partner))
      end

      it 'sets a flash error message' do
        get partner_managed_portfolios_path(partner)
        expect(flash[:error]).to eq("Sorry, you don't have permission to create a portfolio for this partner.")
      end
    end

    context 'when the donor has permission' do
      before do
        allow_any_instance_of(ManagedPortfoliosController).to receive(:ensure_donor_has_permission!).and_return(true)
      end

      it 'does not redirect' do
        get partner_managed_portfolios_path(partner)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
