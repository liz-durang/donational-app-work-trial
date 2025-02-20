require 'rails_helper'

RSpec.describe 'GET /portfolio', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:organizations) { create_list(:organization, 3) }
  let(:subscription) { create(:subscription, donor: donor) }
  let(:first_contribution) { create(:contribution, donor: donor) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Portfolios::GetActivePortfolio).to receive(:call).and_return(portfolio)
    allow(Portfolios::GetPortfolioManager).to receive(:call).and_return(double(name: 'Portfolio Manager'))
    allow(Portfolios::GetActiveAllocations).to receive(:call).and_return(organizations.map { |org| double(organization: org) })
    allow(Contributions::GetActiveSubscription).to receive(:call).and_return(subscription)
    allow(Contributions::GetFirstContribution).to receive(:call).and_return(first_contribution)
  end

  it 'returns a successful response' do
    get portfolio_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the show template' do
    get portfolio_path
    expect(response).to render_template(:show)
  end

  it 'assigns the correct view model' do
    get portfolio_path
    expect(assigns(:view_model).donor_first_name).to eq(donor.first_name)
    expect(assigns(:view_model).organizations).to eq(organizations)
    expect(assigns(:view_model).managed_portfolio?).to be true
    expect(assigns(:view_model).portfolio_manager_name).to eq('Portfolio Manager')
    expect(assigns(:view_model).subscription).to eq(subscription)
    expect(assigns(:view_model).first_contribution).to eq(first_contribution)
    expect(assigns(:view_model).show_modal).to be false
    expect(assigns(:view_model).show_blank_state).to be false
    expect(assigns(:view_model).currency).to eq(Money.default_currency)
  end
end
