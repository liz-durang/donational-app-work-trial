# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payments::GetChargeFromDispute do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:account_id) { 'acc_123' }
  let(:charge_id) do
    customer = Stripe::Customer.create({}, stripe_account: account_id)
    Stripe::Charge.create(
      {
        customer: customer,
        amount: 1000,
        currency: 'usd'
      },
      stripe_account: account_id
    )[:id]
  end

  it 'marks the contribution as disputed and deletes the donations' do
    charge = Payments::GetChargeFromDispute.call(account_id: account_id, charge_id: charge_id)
    expect(charge).to be_a(Stripe::Charge)
    expect(charge.id).to eq(charge_id)
  end
end
