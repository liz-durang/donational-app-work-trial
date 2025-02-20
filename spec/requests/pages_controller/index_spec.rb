require 'rails_helper'

RSpec.describe 'GET /', type: :request do
  it 'returns a successful response' do
    get root_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the index template' do
    get root_path
    expect(response).to render_template(:index)
  end

  it 'assigns the correct view model' do
    get root_path
    expect(assigns(:view_model)).not_to be_nil
  end
end
