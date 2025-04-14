require 'rails_helper'
require 'faraday'

RSpec.describe TriggerContributionProcessedWebhook, type: :job do
  let(:contribution_id) { 1 }
  let(:partner_id) { 1 }
  let(:current_partner) { double('Partner', api_key: 'test_api_key', zapier_webhooks: zapier_webhooks) }
  let(:zapier_webhooks) { double('ZapierWebhooks', find_by: webhook) }
  let(:webhook) { double('Webhook', hook_url: 'http://example.com/webhook') }
  let(:contribution) { double('Contribution', donor_id: 1, processed_at: Time.zone.now, amount_dollars: 100) }
  let(:response) { double('Response', status: 200) }

  before do
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner_id).and_return(current_partner)
    allow(Contributions::GetContributionById).to receive(:call).with(id: contribution_id).and_return(contribution)
    allow(Hooks::GetZapierWebhookByType).to receive(:call).with(partner: current_partner, hook_type: 'process_contribution').and_return(webhook)
    allow(Faraday).to receive(:new).and_return(double(post: response))
  end

  it 'triggers the contribution processed webhook' do
    expect(Faraday).to receive(:new).with(url: 'http://example.com/webhook').and_yield(double(headers: {}, adapter: nil)).and_return(double(post: response))
    expect(response).to receive(:status).and_return(200)

    described_class.perform_inline(contribution_id, partner_id)
  end

  context 'when the webhook response status is not 200 or 410' do
    let(:response) { double('Response', status: 500) }

    it 'raises an error' do
      expect { described_class.perform_inline(contribution_id, partner_id) }.to raise_error(RuntimeError)
    end
  end
end
