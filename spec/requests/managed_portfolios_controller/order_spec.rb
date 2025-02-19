require 'rails_helper'

RSpec.describe 'PUT /partners/:partner_id/managed_portfolios/order', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:managed_portfolios) { create_list(:managed_portfolio, 3, partner: partner) }
  let(:managed_portfolio_ids_in_display_order) { managed_portfolios.map(&:id).shuffle }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ManagedPortfoliosController).to receive(:partner).and_return(partner)
  end


  context 'when donor has permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
    end

    context 'when the order is updated successfully' do
      it 'updates the display order of the managed portfolios' do
        expect {
          put order_partner_managed_portfolios_path(partner), params: { managed_portfolio_ids_in_display_order: managed_portfolio_ids_in_display_order }
        }.to change { managed_portfolios.map { |mp| mp.reload.display_order } }
      end

      it 'returns a successful response' do
        put order_partner_managed_portfolios_path(partner), params: { managed_portfolio_ids_in_display_order: managed_portfolio_ids_in_display_order }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
