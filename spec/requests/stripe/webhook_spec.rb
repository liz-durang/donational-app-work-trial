# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST webhook', type: :request do
  let(:headers) do
    { 'CONTENT_TYPE' => 'application/json' }
  end

  describe 'charge.succeeded' do
    let(:params) do
      {
        id: 'evt_3KMvkvLVTYFX0Htp1OiLZ5PR',
        object: 'event',
        api_version: '2020-08-27',
        created: 1_643_381_334,
        type: 'charge.succeeded',
        data: {
          object: charge
        },
        request: {
          id: 'req_mCiBc0ky419ObA',
          idempotency_key: '2b86b1b1-ccb0-4c09-a183-b22c1da8dfbd'
        },
        account: account_id
      }
    end
    let(:charge) do
      {
        'id' => charge_id,
        'object' => 'charge',
        'amount' => 1000,
        'created' => 1_643_379_468,
        'currency' => 'usd',
        'livemode' => false,
        'metadata' => {
          'contribution_id' => contribution.id
        },
        'payment_intent' => nil,
        'payment_method_details' => {
          'type' => payment_method_type
        },
        'status' => 'succeeded'
      }
    end
    let(:account_id) { 'acct_1CkEP6CqQ8lwp5WU' }
    let(:charge_id) { 'ch_3KMvkvLVTYFX0Htp1s33E7tF' }
    let(:contribution) { create(:contribution) }

    context 'when payment method type is card' do
      let(:payment_method_type) { 'card' }

      it 'processes the contribution payment' do
        expect(Contributions::ProcessContributionPaymentSucceeded)
          .to receive(:run)
          .with(contribution:, receipt: charge.to_json)
          .and_return(double(success?: true))

        post webhook_path, params: params.to_json, headers: headers

        expect(response.status).to eq(200)
      end
    end

    context 'when payment method type is ACSS debit' do
      let(:payment_method_type) { 'acss_debit' }

      it 'processes the contribution payment' do
        expect(Contributions::ProcessContributionAcssOrBacsPaymentSucceeded)
          .to receive(:run)
          .with(charge: instance_of(Stripe::Charge), account_id:)
          .and_return(double(success?: true))

        post webhook_path, params: params.to_json, headers: headers

        expect(response.status).to eq(200)
      end
    end

    context 'when payment method type is BACS debit' do
      let(:payment_method_type) { 'bacs_debit' }

      it 'processes the contribution payment' do
        expect(Contributions::ProcessContributionAcssOrBacsPaymentSucceeded)
          .to receive(:run)
          .with(charge: instance_of(Stripe::Charge), account_id:)
          .and_return(double(success?: true))

        post webhook_path, params: params.to_json, headers: headers

        expect(response.status).to eq(200)
      end
    end
  end

  describe 'charge.failed' do
    let(:params) do
      {
        id: 'evt_3KMvzkLVTYFX0Htp1DLTEDLk',
        object: 'event',
        api_version: '2020-08-27',
        created: 1_643_382_252,
        type: 'charge.failed',
        data: {
          object: charge
        },
        request: {
          id: 'req_tKUkw9b0Do9oTw',
          idempotency_key: '7b2397ff-f8b0-4685-b5e9-64098f0d4287'
        },
        account: account_id
      }
    end
    let(:charge) do
      {
        'id' => charge_id,
        'object' => 'charge',
        'amount' => 1000,
        'created' => 1_643_379_468,
        'currency' => 'usd',
        failure_code: 'card_declined',
        failure_message: 'Your card was declined.',
        'livemode' => false,
        'metadata' => {
          'contribution_id' => contribution.id
        },
        'payment_intent' => nil,
        'payment_method_details' => {},
        'status' => 'failed'
      }
    end
    let(:account_id) { 'acct_1CkEP6CqQ8lwp5WU' }
    let(:charge_id) { 'ch_3KMvzkLVTYFX0Htp1IwEO0Sb' }
    let(:contribution) { create(:contribution) }

    it 'processes the contribution payment' do
      expect(Contributions::ProcessContributionPaymentFailed)
        .to receive(:run)
        .with(contribution:, errors: instance_of(String))
        .and_return(double(success?: true))

      post webhook_path, params: params.to_json, headers: headers

      expect(response.status).to eq(200)
    end
  end

  describe 'setup_intent.succeeded' do
    let(:params) do
      {
        id: 'evt_1CiPtv2eZvKYlo2CcUZsDcO6',
        object: 'event',
        api_version: '2018-05-21',
        created: 1_530_291_411,
        type: 'setup_intent.succeeded',
        data: {
          object: setup_intent
        }
      }
    end
    let(:setup_intent) do
      {
        id: 'seti_1KEYLbLVTYFX0HtpreRhfh0q',
        object: 'setup_intent',
        application: nil,
        cancellation_reason: nil,
        client_secret: 'seti_1KEYLbLVTYFX0HtpreRhfh0q_secret_KuN5sdtp69hze8nG9gimeZGco3ZV6I1',
        created: 1_641_384_727,
        customer: 'cus_KuN5JMXAs5rOM8',
        description: nil,
        last_setup_error: nil,
        latest_attempt: 'setatt_1KEYLoLVTYFX0HtpwX5UO9B4',
        livemode: false,
        mandate: 'mandate_1KEYLoLVTYFX0HtpC9w3dUiB',
        metadata: {},
        next_action: nil,
        on_behalf_of: nil,
        payment_method: payment_method_id,
        payment_method_options: {
          acss_debit: {
            currency: 'cad',
            mandate_options: {
              interval_description: 'on the 15th of every month, starting Jan 2022',
              payment_schedule: 'interval',
              transaction_type: 'personal'
            },
            verification_method: 'automatic'
          }
        },
        payment_method_types: ['acss_debit'],
        single_use_mandate: nil,
        status: 'succeeded',
        usage: 'off_session'
      }
    end

    context 'when the payment method type is not acss_debit' do
      let(:payment_method_id) { payment_method.payment_processor_source_id }
      let(:payment_method) do
        create(:bacs_debit_payment_method, payment_processor_source_id: 'pm_1KEYLlLVTYFX0Htp1vL4L722')
      end

      it 'does not perform any updates and returns a successful response' do
        expect(Payments::UpdateCustomerAcssDebitDetails).not_to receive(:run)

        post webhook_path, params: params.to_json, headers: headers

        expect(response).to have_http_status(:success)
      end
    end

    context 'when the payment method is found' do
      let(:payment_method_id) { payment_method.payment_processor_source_id }
      let(:payment_method) do
        create(:acss_debit_payment_method, payment_processor_source_id: 'pm_1KEYLlLVTYFX0Htp1vL4L722')
      end
      let!(:partner) { create(:partner, :default) }

      it 'returns a successful response' do
        expect(Payments::UpdateCustomerAcssDebitDetails)
          .to receive(:run)
          .with(
            customer_id: 'cus_KuN5JMXAs5rOM8',
            payment_method_id: payment_method.payment_processor_source_id,
            donor_id: payment_method.donor_id,
            account_id: partner.payment_processor_account_id
          ).and_return(double(success?: true))

        post webhook_path, params: params.to_json, headers: headers

        expect(response).to have_http_status(:success)
      end
    end

    context 'when the payment method is not found' do
      let(:payment_method_id) { 'pm_1KEYLlLVTYFX0Htp1vL4L722' }

      it 'returns a failure response' do
        expect(Payments::UpdateCustomerAcssDebitDetails).not_to receive(:run)

        post webhook_path, params: params.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'setup_intent.setup_failed' do
    let(:params) do
      {
        id: 'evt_1CiPtv2eZvKYlo2CcUZsDcO6',
        object: 'event',
        api_version: '2018-05-21',
        created: 1_530_291_411,
        type: 'setup_intent.setup_failed',
        data: {
          object: setup_intent
        }
      }
    end
    let(:setup_intent) do
      {
        id: 'seti_1KEYLbLVTYFX0HtpreRhfh0q',
        object: 'setup_intent',
        application: nil,
        cancellation_reason: nil,
        client_secret: 'seti_1KErxRLVTYFX0HtpRXB6lAR4_secret_KuhM8kUrpSo5ukBGrM88J2ByyrKWVUn',
        created: 1_641_460_109,
        customer: 'cus_KuN5JMXAs5rOM8',
        description: nil,
        last_setup_error: {
          code: 'payment_method_microdeposit_verification_attempts_exceeded',
          doc_url: 'https://stripe.com/docs/error-codes/payment-method-microdeposit-verification-attempts-exceeded',
          message: 'You have exceeded the number of allowed verification attempts.',
          payment_method: {
            id: payment_method_payment_processor_source_id,
            object: 'payment_method',
            acss_debit: {
              bank_name: 'STRIPE TEST BANK',
              fingerprint: 'DEVrZYsxRxNXrufb',
              institution_number: '000', last4: '2227', transit_number: '11000'
            },
            billing_details: {},
            created: 1_641_460_230,
            customer: nil,
            livemode: false,
            metadata: {},
            type: 'acss_debit'
          },
          type: 'invalid_request_error'
        },
        latest_attempt: 'setatt_1KEYLoLVTYFX0HtpwX5UO9B4',
        livemode: false,
        mandate: 'mandate_1KEYLoLVTYFX0HtpC9w3dUiB',
        metadata: {},
        next_action: nil,
        on_behalf_of: nil,
        payment_method: nil,
        payment_method_options: {
          acss_debit: {
            currency: 'cad',
            mandate_options: {
              interval_description: 'on the 15th of every month, starting Jan 2022',
              payment_schedule: 'interval',
              transaction_type: 'personal'
            },
            verification_method: 'automatic'
          }
        },
        payment_method_types: ['acss_debit'],
        single_use_mandate: nil,
        status: 'requires_payment_method',
        usage: 'off_session'
      }
    end
    let(:payment_method_payment_processor_source_id) { 'pm_1KEYLlLVTYFX0Htp1vL4L722' }
    let!(:payment_method) do
      create(:acss_debit_payment_method, payment_processor_source_id: payment_method_payment_processor_source_id)
    end

    it 'destroys the corresponding payment method' do
      expect do
        post webhook_path, params: params.to_json, headers: headers
      end.to change { PaymentMethod.count }.by(-1)

      expect(response).to have_http_status(:success)
      expect(PaymentMethod.find_by(payment_processor_source_id: payment_method_payment_processor_source_id)).to be_nil
    end
  end

  describe 'charge.dispute.created' do
    let(:params) do
      {
        id: 'evt_3KMwCiLVTYFX0Htp0fUUtr5K',
        object: 'event',
        api_version: '2020-08-27',
        created: 1_643_379_468,
        type: 'charge.dispute.created',
        data: {
          object: dispute
        },
        livemode: false,
        pending_webhooks: 2,
        request: {
          id: 'req_eXdYwODhq7dU3g',
          idempotency_key: 'aff63da6-55e5-4b34-b14d-dae658060fef'
        },
        account: account_id
      }
    end
    let(:dispute) do
      {
        'id' => 'dp_1KMvGqLVTYFX0Htp1nkAUMa8',
        'object' => 'dispute',
        'amount' => 1000,
        'balance_transaction' => nil,
        'balance_transactions' => [],
        'charge' => charge_id,
        'created' => 1_643_379_468,
        'currency' => 'usd',
        'evidence' => {},
        'evidence_details' => {
          'due_by' => 1_644_191_999,
          'has_evidence' => false,
          'past_due' => false,
          'submission_count' => 0
        },
        'is_charge_refundable' => true,
        'livemode' => false,
        'metadata' => {},
        'payment_intent' => nil,
        'reason' => 'fraudulent',
        'status' => 'warning_needs_response'
      }
    end
    let(:charge) do
      customer = Stripe::Customer.create({}, stripe_account: account_id)
      Stripe::Charge.create(
        {
          customer:,
          amount: 1000,
          currency: 'usd',
          metadata: { contribution_id: }
        },
        { stripe_account: account_id }
      )
    end
    let(:account_id) { 'acct_1CkEP6CqQ8lwp5WU' }
    let(:charge_id) { 'ch_3KMvGpLVTYFX0Htp11rNtFbA' }
    let(:contribution_id) { SecureRandom.uuid }

    before { StripeMock.start }
    after { StripeMock.stop }

    it 'marks contribution as disputed' do
      expect(Payments::GetChargeFromDispute)
        .to receive(:call)
        .with(account_id:, charge_id:)
        .and_return(charge)

      expect(Contributions::DisputeContribution)
        .to receive(:run)
        .with(contribution_id:)
        .and_return(double(success?: true))

      post webhook_path, params: params.to_json, headers: headers

      expect(response.status).to eq(200)
    end
  end
end
