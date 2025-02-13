require 'rails_helper'

RSpec.describe 'GET /accounts/edit', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor, email: 'email@email.com') }
  let(:partner) { create(:partner) }

  before do
    login_as(donor)
    allow_any_instance_of(AccountsController).to receive(:partner).and_return(partner)
  end

  it 'renders the edit template' do
    get '/accounts/edit'
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:edit)

    expect(response.body).to include('Account Settings')
    expect(response.body).to include(donor.first_name)
    expect(response.body).to include(donor.last_name)
    expect(response.body).to include(donor.email)
  end
end
