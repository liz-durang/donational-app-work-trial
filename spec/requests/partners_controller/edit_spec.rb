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

  context 'when the donor does not have permission' do
    let(:other_partner) { create(:partner) } # A partner not associated with the donor

    before do
      # Ensure current_donor.partners.exists?(id: partner.id) is false
      # The partner being accessed is 'other_partner'
      allow_any_instance_of(PartnersController).to receive(:partner).and_return(other_partner)
      # And the current_donor has no association to 'other_partner'
      allow(donor).to receive(:partners).and_return(Partner.none) # or Partner.where(id: partner.id) if partner is different from other_partner
    end

    it 'redirects to the edit partner path of the accessed partner' do
      get edit_partner_path(other_partner)
      expect(response).to redirect_to(edit_partner_path(other_partner))
    end

    it 'sets a flash error message' do
      get edit_partner_path(other_partner)
      expect(flash[:error]).to eq("Sorry, you don't have permission to update this partner account")
    end
  end
end
