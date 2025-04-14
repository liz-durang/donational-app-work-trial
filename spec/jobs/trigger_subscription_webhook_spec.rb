require 'rails_helper'
require 'faraday'

RSpec.describe TriggerSubscriptionWebhook, type: :job do
  let(:action) { 'create' }
  let(:partner_id) { 1 }
  let(:subscription_id) { 1 }
  let(:partner) { double('Partner', api_key: 'test_api_key') }
  let(:hook) { double('Webhook', hook_url: 'http://example.com/webhook') }
  let(:subscription) { double('Subscription', id: subscription_id, donor: donor, portfolio: portfolio, start_at: Time.zone.now, frequency: 'monthly', amount_dollars: 100, donor_name: 'John Doe', donor_email: 'john.doe@example.com', partner_contribution_percentage: 10, trial_active?: false, updated_at: Time.zone.now, deactivated_at: nil, trial_deactivated_at: nil) }
  let(:donor) { double('Donor', id: 1, name: 'John Doe', first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com', created_at: Time.zone.now) }
  let(:portfolio) { double('Portfolio', managed_portfolio: managed_portfolio) }
  let(:managed_portfolio) { double('ManagedPortfolio', name: 'Managed Portfolio') }
  let(:affiliation) { double('Affiliation', donor_responses: [double('Response', question: double('Question', name: 'Question 1'), value: 'Answer 1')], campaign_title: 'Campaign', partner_name: 'Partner') }
  let(:payment_method) { double('PaymentMethod', payment_type: 'credit_card') }
  let(:response) { double('Response', status: 200) }

  before do
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner_id).and_return(partner)
    allow(Hooks::GetZapierWebhookByType).to receive(:call).with(partner: partner, hook_type: 'create_recurring_contribution').and_return(hook)
    allow(Contributions::GetSubscriptionById).to receive(:call).with(id: subscription_id).and_return(subscription)
    allow(Partners::GetPartnerAffiliationByDonorAndPartner).to receive(:call).with(donor: donor, partner: partner).and_return(affiliation)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor: donor).and_return(payment_method)
    allow(Faraday).to receive(:new).and_return(double(post: response))
  end

  it 'triggers the subscription webhook' do
    expect(Faraday).to receive(:new).with(url: 'http://example.com/webhook').and_yield(double(headers: {}, adapter: nil)).and_return(double(post: response))
    expect(response).to receive(:status).and_return(200)

    described_class.perform_inline(action, partner_id, subscription_id)
  end

  context 'when the webhook response status is not 200 or 410' do
    let(:response) { double('Response', status: 500) }

    it 'raises an error' do
      expect { described_class.perform_inline(action, partner_id, subscription_id) }.to raise_error(RuntimeError)
    end
  end
end
