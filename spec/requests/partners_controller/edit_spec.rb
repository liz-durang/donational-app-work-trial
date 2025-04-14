require 'rails_helper'

RSpec.describe 'GET /partners/:id/edit', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(PartnersController).to receive(:partner).and_return(partner)
    allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
  end

  it 'returns a successful response' do
    get edit_partner_path(partner)
    expect(response).to have_http_status(:success)
  end

  it 'renders the edit template' do
    get edit_partner_path(partner)
    expect(response).to render_template(:edit)
  end

  it 'assigns the correct view model' do
    get edit_partner_path(partner)
    expect(assigns(:view_model).donor).to eq(donor)
    expect(assigns(:view_model).partner).to eq(partner)
    expect(assigns(:view_model).partner_path).to eq(partner_path)
    expect(assigns(:view_model).stripe_connect_url).to eq("https://connect.stripe.com/oauth/authorize?response_type=code&client_id=#{ENV.fetch(
      'STRIPE_CLIENT_ID', ''
    )}&scope=read_write&state=#{partner.id}")
    expect(assigns(:view_model).donor_questions_with_blank_new_question.map(&:name)).to include(nil)
    expect(assigns(:view_model).donor_questions_with_blank_new_question.last).to be_an_instance_of(Partner::DonorQuestion)
  end
end
