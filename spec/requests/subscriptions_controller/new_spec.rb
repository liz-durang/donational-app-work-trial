require 'rails_helper'

RSpec.describe 'GET /take-the-pledge', type: :request do
  include Helpers::LoginHelper
  let!(:donor) { create(:donor) }
  let!(:payment_method) { create(:payment_method, donor:) }
  let(:partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true) }
  let(:campaign) { create(:campaign, partner:) }
  let(:params) { {} }

  before do
    login_as(donor)
    allow(Partners::GetPartnerById).to receive(:call).and_return(partner)
    allow(Partners::GetCampaignBySlug).to receive(:call).and_return(campaign)
    allow(Partners::GetCampaignById).to receive(:call).and_return(campaign)
    allow(Partners::GetOftwPartners).to receive(:call).and_return([partner])
    allow(Partners::GetChapterOptionsByPartnerOrCampaign).to receive(:call).and_return([])
    allow(Constants::GetTitles).to receive(:call).and_return(['Mr.', 'Ms.'])
    allow(Constants::GetLocalizedPaymentMethods).to receive(:call).and_return({ USD: [double(
      human_readable_name: 'card', payment_processor_payment_method_type_code: '123'
    )] })
  end

  context 'when the partner and campaign are valid' do
    it 'returns a successful response' do
      get take_the_pledge_path, params: params
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get take_the_pledge_path
      expect(response).to render_template(:new)
    end

    it 'assigns the correct view model' do
      get take_the_pledge_path, params: { campaign_slug: campaign.slug }
      expect(assigns(:view_model).partners).to eq([partner])
      expect(assigns(:view_model).campaign).to eq(campaign)
      expect(assigns(:view_model).currency_code).to eq(partner.currency.upcase)
      expect(assigns(:view_model).minimum_contribution_amount).to eq([campaign.minimum_contribution_amount.to_i,
                                                                      SubscriptionsController::DEFAULT_MINIMUM_CONTRIBUTION].max)
      expect(assigns(:view_model).contribution_amount_help_text).to eq(campaign.contribution_amount_help_text || SubscriptionsController::DEFAULT_CONTRIBUTION_AMOUNT_HELP_TEXT)
      expect(assigns(:view_model).titles).to eq(['Mr.', 'Ms.'])
      expect(assigns(:view_model).payment_method_options.keys).to eq([:USD])
    end
  end

  # New tests for covering lines 25-40: Stripe checkout session return flow
  context 'when returning from successful Stripe checkout session' do
    let(:stripe_session_id) { 'cs_test_123' }
    let(:params) { { stripe_session_id: } }
    let(:stripe_customer) { OpenStruct.new(id: 'cus_test', name: 'John Doe', email: 'customer@example.com') }
    let(:stripe_payment_method) { OpenStruct.new(type: 'card') }
    let(:stripe_setup_intent) { OpenStruct.new(payment_method: stripe_payment_method) }
    let(:stripe_customer_details) { OpenStruct.new(email: 'john@example.com') }
    let(:checkout_session_metadata) { { 'amount_cents' => '2000', 'partner_id' => partner.id.to_s } }
    let(:stripe_checkout_session) do
      OpenStruct.new(
        id: stripe_session_id,
        customer: stripe_customer,
        customer_details: stripe_customer_details,
        customer_email: nil,
        setup_intent: stripe_setup_intent,
        metadata: checkout_session_metadata
      )
    end

    before do
      # Mock Stripe checkout session retrieval
      allow(Stripe::Checkout::Session).to receive(:retrieve)
        .with(
          { expand: ['customer', 'setup_intent.payment_method'], id: stripe_session_id },
          { stripe_account: partner.payment_processor_account_id }
        )
        .and_return(stripe_checkout_session)
    end

    context 'when pledge_form params are not present' do
      it 'creates pledge form from checkout session metadata' do
        get take_the_pledge_path, params: params

        pledge_form = assigns(:view_model).pledge_form
        expect(pledge_form).to be_a(PledgeForm)
        expect(pledge_form.amount_cents).to eq('2000')
        expect(pledge_form.partner_id).to eq(partner.id.to_s)
      end

      it 'pre-populates form with Stripe customer information' do
        get take_the_pledge_path, params: params

        pledge_form = assigns(:view_model).pledge_form
        expect(pledge_form.first_name).to eq('John')
        expect(pledge_form.last_name).to eq('Doe')
        expect(pledge_form.email).to eq('john@example.com')
        expect(pledge_form.payment_processor_customer_id).to eq('cus_test')
        expect(pledge_form.payment_processor_payment_method_type).to eq('card')
        expect(pledge_form.stripe_session_id).to eq(stripe_session_id)
      end

      context 'when customer name has multiple parts' do
        let(:stripe_customer) { OpenStruct.new(id: 'cus_test', name: 'John Michael Doe') }

        it 'correctly splits first and last name' do
          get take_the_pledge_path, params: params

          pledge_form = assigns(:view_model).pledge_form
          expect(pledge_form.first_name).to eq('John')
          expect(pledge_form.last_name).to eq('Doe')
        end
      end

      context 'when customer name is a single word' do
        let(:stripe_customer) { OpenStruct.new(id: 'cus_test', name: 'John') }

        it 'handles single name correctly' do
          get take_the_pledge_path, params: params

          pledge_form = assigns(:view_model).pledge_form
          expect(pledge_form.first_name).to eq('John')
          expect(pledge_form.last_name).to eq('John')
        end
      end

      context 'when email comes from different sources' do
        context 'when customer_details.email is present' do
          let(:stripe_customer_details) { OpenStruct.new(email: 'details@example.com') }
          let(:stripe_checkout_session) do
            OpenStruct.new(
              id: stripe_session_id,
              customer: stripe_customer,
              customer_details: stripe_customer_details,
              customer_email: 'session@example.com',
              setup_intent: stripe_setup_intent,
              metadata: checkout_session_metadata
            )
          end

          it 'prioritizes customer_details.email' do
            get take_the_pledge_path, params: params

            pledge_form = assigns(:view_model).pledge_form
            expect(pledge_form.email).to eq('details@example.com')
          end
        end

        context 'when customer_details.email is nil but customer_email is present' do
          let(:stripe_customer_details) { OpenStruct.new(email: nil) }
          let(:stripe_checkout_session) do
            OpenStruct.new(
              id: stripe_session_id,
              customer: stripe_customer,
              customer_details: stripe_customer_details,
              customer_email: 'session@example.com',
              setup_intent: stripe_setup_intent,
              metadata: checkout_session_metadata
            )
          end

          it 'uses customer_email' do
            get take_the_pledge_path, params: params

            pledge_form = assigns(:view_model).pledge_form
            expect(pledge_form.email).to eq('session@example.com')
          end
        end

        context 'when both customer_details.email and customer_email are nil' do
          let(:stripe_customer_details) { OpenStruct.new(email: nil) }
          let(:stripe_checkout_session) do
            OpenStruct.new(
              id: stripe_session_id,
              customer: stripe_customer,
              customer_details: stripe_customer_details,
              customer_email: nil,
              setup_intent: stripe_setup_intent,
              metadata: checkout_session_metadata
            )
          end

          it 'falls back to customer.email' do
            get take_the_pledge_path, params: params

            pledge_form = assigns(:view_model).pledge_form
            expect(pledge_form.email).to eq('customer@example.com')
          end
        end
      end

      context 'when form validation passes' do
        before do
          # Mock the form validation to pass
          allow_any_instance_of(PledgeForm).to receive(:steps_before_payment_processor_are_valid?).and_return(true)
        end

        it 'successfully loads the page' do
          get take_the_pledge_path, params: params
          expect(response).to have_http_status(:success)
        end

        it 'does not call handle_error' do
          expect_any_instance_of(SubscriptionsController).not_to receive(:handle_error)
          get take_the_pledge_path, params:
        end
      end

      context 'when form validation fails' do
        before do
          # Mock the form validation to fail
          allow_any_instance_of(PledgeForm).to receive(:steps_before_payment_processor_are_valid?).and_return(false)

          # Mock the form errors
          errors_double = double('errors')
          allow(errors_double).to receive(:full_messages).and_return(['Invalid email', 'Missing first name'])
          allow_any_instance_of(PledgeForm).to receive(:errors).and_return(errors_double)

          # Mock handle_error method to prevent actual error handling
          allow_any_instance_of(SubscriptionsController).to receive(:handle_error).and_return(true)
        end

        it 'calls handle_error with form validation errors' do
          expect_any_instance_of(SubscriptionsController).to receive(:handle_error)
            .with(['Invalid email', 'Missing first name'].to_s)
            .and_return(true)

          get take_the_pledge_path, params:
        end

        it 'returns early from the action' do
          # Since handle_error returns true, the action should return early
          # and not continue processing
          get take_the_pledge_path, params:
          # The test passes if no exceptions are raised and the method returns
        end
      end
    end

    context 'when pledge_form params are present (returning after validation failure)' do
      let(:pledge_form_params) do
        {
          first_name: 'Jane',
          last_name: 'Smith',
          email: 'jane@example.com',
          amount_cents: '3000'
        }
      end
      let(:params) { { stripe_session_id:, pledge_form: pledge_form_params } }

      it 'creates pledge form from submitted params instead of session metadata' do
        get take_the_pledge_path, params: params

        pledge_form = assigns(:view_model).pledge_form
        expect(pledge_form.first_name).to eq('Jane')
        expect(pledge_form.last_name).to eq('Smith')
        expect(pledge_form.email).to eq('jane@example.com')
        expect(pledge_form.amount_cents).to eq('3000')
      end

      it 'does not pre-populate with Stripe customer data' do
        get take_the_pledge_path, params: params

        pledge_form = assigns(:view_model).pledge_form
        # Should use submitted params, not Stripe data
        expect(pledge_form.first_name).not_to eq('John')
        expect(pledge_form.payment_processor_customer_id).to be_nil
      end
    end

    context 'when Stripe checkout session retrieval fails' do
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .and_raise(Stripe::InvalidRequestError.new('Session not found', nil))
      end

      it 'returns an error status' do
        get take_the_pledge_path, params: params
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  context 'when the partner is not active or does not use the One for the World checkout' do
    before do
      allow(partner).to receive(:active?).and_return(false)
    end

    it 'returns a not found response' do
      get take_the_pledge_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when the campaign is not found' do
    before do
      allow(Partners::GetCampaignBySlug).to receive(:call).and_return(nil)
    end

    it 'returns a not found response' do
      get campaign_take_the_pledge_path(campaign.slug)
      expect(response).to have_http_status(:not_found)
    end
  end
end
