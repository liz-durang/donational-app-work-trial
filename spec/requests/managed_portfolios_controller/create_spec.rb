require 'rails_helper'

RSpec.describe 'POST /partners/:partner_id/managed_portfolios', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper
  include Helpers::MediaHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:managed_portfolio_params) do
    {
      title: 'New Portfolio',
      description: 'Portfolio Description',
      featured: true,
      image: sample_image,
      charities: 'charity1;charity2;charity3'
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
  end

  context 'when donor has permission' do
    let(:params) { { managed_portfolio: managed_portfolio_params, charities: 'name,ein;name2,ein'} }
    
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    context 'when the portfolio is created successfully' do
      before do
        allow(Portfolios::CreateManagedPortfolio).to receive(:run).and_return(double(success?:true, result: 1))
      end
  
      it 'redirects to the edit partner managed portfolio path' do
        post partner_managed_portfolios_path(partner), params: params
        expect(response).to redirect_to(edit_partner_managed_portfolio_path(partner, 1))
      end
  
      it 'sets a flash success message' do
        post partner_managed_portfolios_path(partner), params: params
        expect(flash[:success]).to eq('Portfolio created successfully.')
      end
    end
  
    context 'when the portfolio creation fails' do
      before do
        allow(Portfolios::CreateManagedPortfolio).to receive(:run).and_return(failure_outcome)
      end
  
      it 'redirects to the new partner managed portfolio path' do
        post partner_managed_portfolios_path(partner), params: params
        expect(response).to redirect_to(new_partner_managed_portfolio_path(partner))
      end
  
      it 'sets a flash error message' do
        post partner_managed_portfolios_path(partner), params: params
        expect(flash[:error]).to eq('Error message')
      end
    end
  end
  
end
