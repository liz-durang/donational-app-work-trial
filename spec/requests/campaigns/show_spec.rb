# frozen_string_literal: true

require 'rails_helper'

describe 'GET campaigns/:slug', type: :request do
  let(:campaign) { create(:campaign, partner: partner) }
  
  describe 'GET show' do
    context 'when the partner is active' do
      let(:partner) { create(:partner, deactivated_at: nil) }

      it 'returns a successful response' do
        get campaigns_path(campaign.slug)

        expect(response).to have_http_status(:success)
      end
    end

    context 'when partner has been deactivated' do
      let(:partner) { create(:partner, deactivated_at: Time.zone.now) }

      it 'does not return the donor' do
        get campaigns_path(campaign.slug)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
