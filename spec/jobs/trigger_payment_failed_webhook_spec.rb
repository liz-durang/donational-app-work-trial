require 'rails_helper'
require 'faraday'

RSpec.describe TriggerPaymentFailedWebhook, type: :job do
  let(:contribution_id) { 1 }
  let(:partner_id) { 1 }
  let(:current_partner) { double('Partner', api_key: 'test_api_key', zapier_webhooks: zapier_webhooks) }
  let(:zapier_webhooks) { double('ZapierWebhooks', find_by: webhook) }
  let(:webhook) { double('Webhook', hook_url: 'http://example.com/webhook') }
  let(:contribution) { double('Contribution', id: contribution_id, donor: donor, portfolio: portfolio, created_at: Time.zone.now, scheduled_at: Time.zone.now, failed_at: Time.zone.now, partner_contribution_percentage: 10, donor_email: 'donor@example.com') }
  let(:donor) { double('Donor', id: 1, name: 'John Doe', first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com', created_at: Time.zone.now) }
  let(:portfolio) { double('Portfolio', managed_portfolio: managed_portfolio) }
  let(:managed_portfolio) { double('ManagedPortfolio', name: 'Managed Portfolio') }
  let(:subscription) { double('Subscription', id: 1, start_at: Time.zone.now, frequency: 'monthly', amount_dollars: 100, partner_contribution_percentage: 10, portfolio: portfolio) }
  let(:affiliation) { double('Affiliation', donor_responses: [double('Response', question: double('Question', name: 'Question 1'), value: 'Answer 1')], campaign_title: 'Campaign', partner_name: 'Partner') }
  let(:response) { double('Response', status: 200) }

  before do
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner_id).and_return(current_partner)
    allow(Contributions::GetContributionById).to receive(:call).with(id: contribution_id).and_return(contribution)
    allow(Hooks::GetZapierWebhookByType).to receive(:call).with(partner: current_partner, hook_type: 'payment_failed').and_return(webhook)
    allow(Contributions::GetActiveSubscription).to receive(:call).with(donor: donor).and_return(subscription)
    allow(Contributions::GetLastDeactivatedSubscription).to receive(:call).with(donor: donor).and_return(nil)
    allow(Partners::GetPartnerAffiliationByDonorAndPartner).to receive(:call).with(donor: donor, partner: current_partner).and_return(affiliation)
    allow(Faraday).to receive(:new).and_return(double(post: response))
  end

  it 'triggers the payment failed webhook' do
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
