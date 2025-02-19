require 'rails_helper'

RSpec.describe 'PUT /partners/:partner_id/managed_portfolios/:id/unarchive', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:managed_portfolio) { create(:managed_portfolio, partner: partner, hidden_at: DateTime.current) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:managed_portfolio).and_return(managed_portfolio)
  end

  context 'when donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    context 'when the portfolio is unarchived successfully' do
      before do
        allow(Portfolios::UnarchiveManagedPortfolio).to receive(:run).and_return(successful_outcome)
      end

      it 'redirects to the partner managed portfolios path' do
        put unarchive_partner_managed_portfolio_path(partner, managed_portfolio)
        expect(response).to redirect_to(partner_managed_portfolios_path(partner))
      end

      it 'sets a flash success message' do
        put unarchive_partner_managed_portfolio_path(partner, managed_portfolio)
        expect(flash[:success]).to eq('Portfolio unarchived successfully.')
      end
    end

    context 'when the portfolio unarchiving fails' do
      before do
        allow(Portfolios::UnarchiveManagedPortfolio).to receive(:run).and_return(double(success?: false, errors: double(message_list: ['Error message'])))
      end

      it 'redirects to the partner managed portfolios path' do
        put unarchive_partner_managed_portfolio_path(partner, managed_portfolio)
        expect(response).to redirect_to(partner_managed_portfolios_path(partner))
      end

      it 'sets a flash error message' do
        put unarchive_partner_managed_portfolio_path(partner, managed_portfolio)
        expect(flash[:error]).to eq('Error message')
      end
    end
  end
end
