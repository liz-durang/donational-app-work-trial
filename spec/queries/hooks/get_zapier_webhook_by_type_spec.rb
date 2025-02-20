require 'rails_helper'

RSpec.describe Hooks::GetZapierWebhookByType, type: :query do
  let(:partner) { create(:partner) }
  let(:hook_type) { 'donation_created' }
  let!(:zapier_webhook) { create(:zapier_webhook, partner: partner, hook_type: hook_type) }
  let!(:other_webhook) { create(:zapier_webhook, partner: partner, hook_type: 'other_type') }
  let!(:different_partner_webhook) { create(:zapier_webhook, partner: create(:partner), hook_type: hook_type) }

  describe '#call' do
    subject { described_class.new.call(partner: partner, hook_type: hook_type) }

    context 'when the webhook exists' do
      it 'returns the zapier webhook with the given partner and hook type' do
        expect(subject).to eq(zapier_webhook)
      end
    end

    context 'when the webhook does not exist' do
      subject { described_class.new.call(partner: partner, hook_type: 'donation_created') }
      let(:hook_type) { 'nonexistent_type' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the webhook belongs to a different partner' do
      subject { described_class.new.call(partner: partner2, hook_type: hook_type) }
      let(:partner2) { create(:partner) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
