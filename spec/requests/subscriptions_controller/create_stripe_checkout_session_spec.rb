require 'rails_helper'

RSpec.describe 'POST /create-checkout-session', type: :request do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true) }
  let(:campaign) { create(:campaign, partner: partner) }
  let(:pledge_form_params) do
    {
      pledge_form: {
        amount_cents: 5000,
        associated_with_chapter: true,
        email: 'john.doe@example.com',
        estimated_future_annual_income: 100000,
        first_name: 'John',
        house_name_or_number: '123',
        last_name: 'Doe',
        managed_portfolio_id: 1,
        partner_id: partner.id,
        payment_method_id: 'pm_test',
        payment_processor_customer_id: 'cus_test',
        payment_processor_payment_method_id: 'pm_test',
        payment_processor_payment_method_type: 'card',
        pledge_percentage: 10,
        postcode: '12345',
        start_at_month: '12',
        start_at_year: '2023',
        start_pledge_in_future: false,
        stripe_session_id: 'sess_test',
        title: 'Mr.',
        trial_amount_dollars: 50,
        uk_gift_aid_accepted: true
      }
    }
  end
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_checkout_session) do
    checkout_session = stripe_helper.create_checkout_session
    customer_details_double = double('customer details')
    allow(checkout_session).to receive(:customer_details).and_return(customer_details_double)
    allow(customer_details_double).to receive(:email).and_return(stripe_customer.email)
    checkout_session
  end
  let(:stripe_customer) { Stripe::Customer.create(name: 'Robert Doe') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).and_return(partner)
    allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
  end

  context 'when the pledge form is valid' do
    before do
      allow(PledgeForm).to receive(:new).and_return(double(steps_before_payment_processor_are_valid?: true))
      allow(Stripe::Checkout::Session).to receive(:create).and_return(double(url: 'https://checkout.stripe.com/pay/sess_test'))
    end

    it 'creates a Stripe Checkout session and returns the session URL' do
      post create_checkout_session_path, params: pledge_form_params
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq('sessionUrlForStripeHostedPage' => 'https://checkout.stripe.com/pay/sess_test')
    end
  end

  context 'when the pledge form is invalid' do
    before do
      allow(PledgeForm).to receive(:new).and_return(double(steps_before_payment_processor_are_valid?: false, errors: double(full_messages: ['Error message'])))
    end

    it 'returns an error response' do
      post create_checkout_session_path, params: pledge_form_params
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq('status' => 500)
    end
  end

  context 'when Stripe raises an error' do
    before do
      allow(PledgeForm).to receive(:new).and_return(double(steps_before_payment_processor_are_valid?: true))
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::InvalidRequestError.new('Invalid request', 'param'))
    end

    it 'returns an error response' do
      post create_checkout_session_path, params: pledge_form_params
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq('status' => 500)
    end
  end
end
