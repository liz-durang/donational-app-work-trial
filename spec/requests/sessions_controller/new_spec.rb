require 'rails_helper'

RSpec.describe 'GET /login', type: :request do
  it 'returns a successful response' do
    get login_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the new template' do
    get login_path
    expect(response).to render_template(:new)
  end
end
