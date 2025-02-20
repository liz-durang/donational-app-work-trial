require 'rails_helper'

RSpec.describe 'POST /take-the-pledge', type: :request do
  include Helpers::CommandHelper
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true, after_donation_thank_you_page_url: 'http://www.example.com/thank-you') }
  let(:partner2) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true, after_donation_thank_you_page_url: 'http://www.example.com/thank-you') }
  let(:managed_portfolio) { create(:managed_portfolio) }

  let(:campaign) { create(:campaign, partner: partner) }
  let(:pledge_form_params) do
    {
      pledge_form: {
        campaign_id: campaign.id,
        amount_cents: 5000,
        associated_with_chapter: true,
        email: 'john.doe@example.com',
        estimated_future_annual_income: 100000,
        first_name: 'John',
        house_name_or_number: '123',
        last_name: 'Doe',
        managed_portfolio_id: managed_portfolio.id,
        partner_id: partner.id,
        payment_method_id: 'pm_test',
        payment_processor_customer_id: 'cus_test',
        payment_processor_payment_method_id: 'pm_test',
        payment_processor_payment_method_type: 'card',
        pledge_percentage: 10,
        postcode: '12345',
        start_at_month: "December",
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
  let(:stripe_setup_intent) { Stripe::SetupIntent.create }
  let(:stripe_checkout_session) do
    checkout_session = stripe_helper.create_checkout_session
    customer_details_double = double('customer details')
    allow(checkout_session).to receive(:customer_details).and_return(customer_details_double)
    allow(customer_details_double).to receive(:email).and_return(stripe_customer.email)
    checkout_session
  end
  let(:stripe_customer) { Stripe::Customer.create(name: 'Robert Doe') }
  let(:stripe_payment_method_type) { 'acss_debit' }
  let(:stripe_payment_method) do
    payment_method = Stripe::PaymentMethod.create(type: 'card')
    allow(payment_method).to receive(:type).and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).and_call_original # Default stub
    allow(payment_method).to receive(:[]).with(:type).and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).with('type').and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).with(stripe_payment_method_type.to_sym).and_return({ bank_name: 'Test Bank',
                                                                                               last4: '3456',
                                                                                               brand: 'Visa' })
    allow(payment_method).to receive(:[]).with(stripe_payment_method_type).and_return({ bank_name: 'Test Bank',
                                                                                        last4: '3456',
                                                                                        brand: 'Visa' })
    payment_method
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    StripeMock.start
  end

  after do
    StripeMock.stop
  end

  context 'when the subscription is created successfully' do
    before do
      allow(Partners::GetPartnerById).to receive(:call).and_return(partner)
      allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
      allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(double(success?: true, result: donor))
      allow(Donors::UpdateDonor).to receive(:run).and_return(successful_outcome)
      allow(Partners::AffiliateDonorWithPartner).to receive(:run).and_return(successful_outcome)
      allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(successful_outcome)
      allow(Portfolios::SelectPortfolio).to receive(:run).and_return(successful_outcome)
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(successful_outcome)
      allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_checkout_session)
      allow(stripe_checkout_session).to receive(:setup_intent).and_return(stripe_setup_intent)
      allow(stripe_setup_intent).to receive(:payment_method).and_return(stripe_payment_method)
    end

    context 'when donor not found' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).and_return(partner2)
      end

      it 'calls create_donor!' do
        expect_any_instance_of(SubscriptionsController).to receive(:create_donor!).and_return(successful_outcome)

        post create_pledge_path, params: pledge_form_params
      end
      
      it 'redirects to the partner after donation thank you page' do
        post create_pledge_path, params: pledge_form_params
        expect(response).to redirect_to(partner.after_donation_thank_you_page_url)
      end
    end

    context 'when donor found' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).and_return(partner)
      end

      it 'does not call create_donor!' do
        expect_any_instance_of(SubscriptionsController).not_to receive(:create_donor!)

        post create_pledge_path, params: pledge_form_params
      end

    end
  end

  context 'when the subscription creation fails' do
    before do
      allow(Partners::GetPartnerById).to receive(:call).and_return(partner)
      allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
      allow(Partners::GetPartnerForDonor).to receive(:call).and_return(partner2)
      allow(Donors::CreateDonorAffiliatedWithPartner).to receive(:run).and_return(failure_outcome)
      allow(Donors::UpdateDonor).to receive(:run).and_return(failure_outcome)
      allow(Partners::AffiliateDonorWithPartner).to receive(:run).and_return(failure_outcome)
      allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(failure_outcome)
      allow(Portfolios::SelectPortfolio).to receive(:run).and_return(failure_outcome)
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(failure_outcome)
      allow(Contributions::CreateOrReplaceSubscription).to receive(:run).and_return(successful_outcome)
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_checkout_session)
      allow(stripe_checkout_session).to receive(:setup_intent).and_return(stripe_setup_intent)
      allow(stripe_setup_intent).to receive(:payment_method).and_return(stripe_payment_method)
    end

    it 'redirects to the stripe success url with an alert message' do
      post create_pledge_path, params: pledge_form_params 

      redirect_to = "http://www.example.com/#{campaign.slug}/take-the-pledge?partner_id=#{partner.id}&pledge_form%5Bamount_cents%5D=5000&pledge_form%5Bassociated_with_chapter%5D=true&pledge_form%5Bemail%5D=john.doe%40example.com&pledge_form%5Bestimated_future_annual_income%5D=100000&pledge_form%5Bfirst_name%5D=John&pledge_form%5Bhouse_name_or_number%5D=123&pledge_form%5Blast_name%5D=Doe&pledge_form%5Bmanaged_portfolio_id%5D=#{managed_portfolio.id}&pledge_form%5Bpartner_id%5D=#{partner.id}&pledge_form%5Bpayment_method_id%5D=pm_test&pledge_form%5Bpayment_processor_customer_id%5D=cus_test&pledge_form%5Bpayment_processor_payment_method_id%5D=pm_test&pledge_form%5Bpayment_processor_payment_method_type%5D=card&pledge_form%5Bpledge_percentage%5D=10&pledge_form%5Bpostcode%5D=12345&pledge_form%5Bstart_at_month%5D=December&pledge_form%5Bstart_at_year%5D=2023&pledge_form%5Bstart_pledge_in_future%5D=false&pledge_form%5Bstripe_session_id%5D=sess_test&pledge_form%5Btitle%5D=Mr.&pledge_form%5Btrial_amount_dollars%5D=50&pledge_form%5Buk_gift_aid_accepted%5D=true&stripe_session_id=sess_test"
      expect(response).to redirect_to(redirect_to)
      expect(flash[:alert]).to eq('Error message')
    end
  end
end
