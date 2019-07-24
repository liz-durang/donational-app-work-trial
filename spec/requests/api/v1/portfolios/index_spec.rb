require 'rails_helper'

describe 'GET api/v1/portfolios/', type: :request do
  let(:partner)             { create(:partner) }
  let(:portfolio)           { create(:portfolio) }
  let(:organization)        { create(:organization) }
  let!(:allocation)         { create(:allocation, organization: organization, portfolio: portfolio, percentage: 100) }
  let!(:managed_portfolio)  { create(:managed_portfolio, partner: partner, portfolio: portfolio) }

  let(:another_partner)                         { create(:partner) }
  let(:another_portfolio)                       { create(:portfolio) }
  let!(:managed_portfolio_from_another_partner) { create(:managed_portfolio, partner: another_partner, portfolio: another_portfolio) }

  describe 'GET index' do
    it 'returns a successful response' do
      get api_v1_portfolios_path, headers: { 'X-Api-Key': partner.api_key }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns partner managed portfolios' do
      get api_v1_portfolios_path, headers: { 'X-Api-Key': partner.api_key }, as: :json

      json = JSON.parse(response.body).with_indifferent_access
      expect(json[:portfolios].count).to be(1)
      expect(json[:portfolios][0][:id]).to eq(managed_portfolio.id)
      expect(json[:portfolios][0][:name]).to eq(managed_portfolio.name)
      expect(json[:portfolios][0][:description]).to eq(managed_portfolio.description)
      expect(json[:portfolios][0][:allocations][0][:organization_ein]).to eq(managed_portfolio.portfolio.active_allocations.first.organization_ein)
      expect(json[:portfolios][0][:allocations][0][:percentage]).to eq(managed_portfolio.portfolio.active_allocations.first.percentage)
    end

    it 'should not return managed portfolios from another partner' do
      get api_v1_portfolios_path, headers: { 'X-Api-Key': partner.api_key }, as: :json

      json        = JSON.parse(response.body).with_indifferent_access
      portfolios  = json[:portfolios].map { |portfolio| portfolio[:id] }
      expect(portfolios).to include(managed_portfolio.id)
      expect(portfolios).not_to include(managed_portfolio_from_another_partner.id)
    end
  end
end
