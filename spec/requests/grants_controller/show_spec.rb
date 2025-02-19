require 'rails_helper'

RSpec.describe 'GET /grants/:short_id', type: :request do
  let(:grant) { create(:grant) }
  let(:donations) { create_list(:donation, 3, grant: grant) }

  before do
    allow_any_instance_of(GrantsController).to receive(:grant_by_short_id).and_return(grant)
    allow(grant).to receive(:donations).and_return(Donation.where(id: donations.pluck(:id)))
  end

  context 'when the grant is found' do
    it 'returns a successful response' do
      get grant_path(grant.short_id)
      expect(response).to have_http_status(:success)
    end

    it 'renders the show template' do
      get grant_path(grant.short_id)
      expect(response).to render_template(:show)
    end

    it 'assigns the correct grant' do
      get grant_path(grant.short_id)
      expect(assigns(:grant)).to eq(grant)
    end

    it 'assigns the correct donations' do
      get grant_path(grant.short_id)
      expect(assigns(:donations)).to eq(donations)
    end
  end
end
