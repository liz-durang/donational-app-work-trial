require 'rails_helper'

RSpec.describe 'GET /:campaign_slug/donation-box', type: :request do
  let(:campaign) { create(:campaign, partner:) }

  context 'when the partner does not use OFTW checkout' do
    describe 'GET show' do
      context 'when the partner is active' do
        let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: false) }

        it 'returns a successful response' do
          get campaigns_path(campaign.slug)

          expect(response).to have_http_status(:success)
          expect(response).not_to redirect_to(review_campaign_take_the_pledge_url(campaign_slug: campaign.slug))
        end
      end

      context 'when partner has been deactivated' do
        let(:partner) { create(:partner, deactivated_at: Time.zone.now, uses_one_for_the_world_checkout: false) }

        it 'does not return the donor' do
          get campaigns_path(campaign.slug)

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
