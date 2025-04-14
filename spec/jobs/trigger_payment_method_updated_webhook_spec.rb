require 'rails_helper'
require 'faraday'

RSpec.describe TriggerPaymentMethodUpdatedWebhook, type: :job do
  let(:donor_id) { 1 }
  let(:donor) { double('Donor', id: donor_id, name: 'John Doe', first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com') }
  let(:current_partner) { double('Partner', api_key: 'test_api_key', zapier_webhooks: zapier_webhooks) }
  let(:zapier_webhooks) { double('ZapierWebhooks', find_by: webhook) }
  let(:webhook) { double('Webhook', hook_url: 'http://example.com/webhook') }
  let(:subscription) { double('Subscription', id: 1) }
  let(:response) { double('Response', status: 200) }

  before do
    allow(Donors::GetDonorById).to receive(:call).with(id: donor_id).and_return(donor)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(current_partner)
    allow(Hooks::GetZapierWebhookByType).to receive(:call).with(partner: current_partner, hook_type: 'update_payment_method').and_return(webhook)
    allow(Contributions::GetActiveSubscription).to receive(:call).with(donor: donor).and_return(subscription)
    allow(Faraday).to receive(:new).and_return(double(post: response))
  end

  it 'triggers the payment method updated webhook' do
    expect(Faraday).to receive(:new).with(url: 'http://example.com/webhook').and_yield(double(headers: {}, adapter: nil)).and_return(double(post: response))
    expect(response).to receive(:status).and_return(200)

    described_class.perform_inline(donor_id)
  end

  context 'when the webhook response status is not 200 or 410' do
    let(:response) { double('Response', status: 500) }

    it 'raises an error' do
      expect { described_class.perform_inline(donor_id) }.to raise_error(RuntimeError)
    end
  end
end
