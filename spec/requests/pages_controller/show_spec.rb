require 'rails_helper'

RSpec.describe 'GET /:slug', type: :request do
  let(:slug) { 'mission' }

  it 'returns a successful response' do
    get "/#{slug}"
    expect(response).to have_http_status(:success)
  end

  it 'renders the show template' do
    get "/#{slug}"
    expect(response).to render_template(slug.underscore)
  end

  it 'assigns the correct page' do
    get "/#{slug}"
    expect(assigns(:view_model).currency_code).to eq("USD")
  end
end
