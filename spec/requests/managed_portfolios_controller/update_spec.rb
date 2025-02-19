require 'rails_helper'

RSpec.describe 'PUT /partners/:partner_id/managed_portfolios/:id', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper
  include Helpers::MediaHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:managed_portfolio) { create(:managed_portfolio, partner: partner) }
  let(:managed_portfolio_params) do
    {
      title: 'Updated Portfolio',
      description: 'Updated Description',
      featured: true,
      archived: false,
      image: sample_image,
      charities: 'charity1;charity2;charity3'
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:managed_portfolio).and_return(managed_portfolio)
  end

  context 'when donor has permission' do
    let(:params) { { managed_portfolio: managed_portfolio_params, charities: 'name,ein;name2,ein'} }
    
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    context 'when the portfolio is updated successfully' do
      before do
        allow(Portfolios::UpdateManagedPortfolio).to receive(:run).and_return(successful_outcome)
      end

      it 'redirects to the edit partner managed portfolio path' do
        put partner_managed_portfolio_path(partner, managed_portfolio), params: params
        expect(response).to redirect_to(edit_partner_managed_portfolio_path(partner, managed_portfolio))
      end

      it 'sets a flash success message' do
        put partner_managed_portfolio_path(partner, managed_portfolio), params: params
        expect(flash[:success]).to eq('Portfolio updated successfully.')
      end
    end

    context 'when the portfolio update fails' do
      before do
        allow(Portfolios::UpdateManagedPortfolio).to receive(:run).and_return(double(success?: false, errors: double(message_list: ['Error message'])))
      end

      it 'redirects to the edit partner managed portfolio path' do
        put partner_managed_portfolio_path(partner, managed_portfolio), params: params
        expect(response).to redirect_to(edit_partner_managed_portfolio_path(partner, managed_portfolio))
      end

      it 'sets a flash error message' do
        put partner_managed_portfolio_path(partner, managed_portfolio), params: params
        expect(flash[:error]).to eq('Error message')
      end
    end
  end
end
