require 'rails_helper'

RSpec.describe 'GET /charities', type: :request do
  let(:recommended_organizations) { create_list(:organization, 3) }

  before do
    allow(Organizations::GetRecommendedOrganizations).to receive(:call).and_return(recommended_organizations)
  end

  it 'returns a successful response' do
    get organizations_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the index template' do
    get organizations_path
    expect(response).to render_template(:index)
  end

  it 'assigns the correct view model' do
    get organizations_path
    expect(assigns(:view_model).organizations).to eq(recommended_organizations)
  end
end
