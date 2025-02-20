require 'rails_helper'

RSpec.describe 'GET /portfolio/new', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:recommended_allocations) { create_list(:allocation, 3) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Portfolios::GetRecommendedAllocations).to receive(:call).and_return(recommended_allocations)
  end

  it 'returns a successful response' do
    get new_portfolio_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the new template' do
    get new_portfolio_path
    expect(response).to render_template(:new)
  end

  it 'assigns the correct view model' do
    get new_portfolio_path
    expect(assigns(:portfolio).donor_first_name).to eq(donor.first_name)
    expect(assigns(:portfolio).allocations).to eq(recommended_allocations)
    expect(assigns(:portfolio).cause_areas).to eq(recommended_allocations.map(&:organization).map(&:cause_area).uniq)
    expect(assigns(:portfolio).diversity_text).to eq(donor.portfolio_diversity)
  end
end
