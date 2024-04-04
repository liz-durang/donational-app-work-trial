# frozen_string_literal: true

require 'rails_helper'

describe 'GET campaigns/:slug', type: :request do
  let(:campaign) { create(:campaign, partner:) }

  describe 'GET new' do
    context 'when the partner is active and uses OFTW checkout flow' do
      let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true) }

      it 'returns a successful response' do
        get review_campaign_take_the_pledge_path(campaign.slug)

        expect(response).to have_http_status(:success)
      end
    end

    context 'when the partner does not use OFTW checkout flow' do
      let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: false) }

      it 'returns a not found response' do
        get review_campaign_take_the_pledge_path(campaign.slug)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when partner has been deactivated' do
      let(:partner) { create(:partner, deactivated_at: Time.zone.now, uses_one_for_the_world_checkout: true) }

      it 'returns a not found response' do
        get review_campaign_take_the_pledge_path(campaign.slug)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
