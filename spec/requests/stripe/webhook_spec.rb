# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST webhook', type: :request do
  describe 'setup_intent.succeeded' do
    let(:headers) do
      { 'CONTENT_TYPE' => 'application/json' }
    end
    let(:params) do
      {
        'id': 'evt_1CiPtv2eZvKYlo2CcUZsDcO6',
        'object': 'event',
        'api_version': '2018-05-21',
        'created': 1530291411,
        'type': 'setup_intent.succeeded',
        'data': {
          'object': setup_intent
        }
      }
    end
    let(:setup_intent) do
      {
        'id': 'seti_1KEYLbLVTYFX0HtpreRhfh0q',
        'object': 'setup_intent',
        'application': nil,
        'cancellation_reason': nil,
        'client_secret': 'seti_1KEYLbLVTYFX0HtpreRhfh0q_secret_KuN5sdtp69hze8nG9gimeZGco3ZV6I1',
        'created': 1641384727,
        'customer': 'cus_KuN5JMXAs5rOM8',
        'description': nil,
        'last_setup_error': nil,
        'latest_attempt': 'setatt_1KEYLoLVTYFX0HtpwX5UO9B4',
        'livemode': false,
        'mandate': 'mandate_1KEYLoLVTYFX0HtpC9w3dUiB',
        'metadata': {},
        'next_action': nil,
        'on_behalf_of': nil,
        'payment_method': payment_method_id,
        'payment_method_options': {
          'acss_debit': {
            'currency': 'cad',
            'mandate_options': {
              'interval_description': 'on the 15th of every month, starting Jan 2022',
              'payment_schedule': 'interval',
              'transaction_type': 'personal'
            },
          'verification_method': 'automatic'
          }
        },
        'payment_method_types': ['acss_debit'],
        'single_use_mandate': nil,
        'status': 'succeeded',
        'usage': 'off_session'
      }
    end


    context 'when the payment method is found' do
      let(:payment_method_id) { payment_method.payment_processor_source_id }
      let(:payment_method) do
        create(:payment_method, :acss_debit, payment_processor_source_id: 'pm_1KEYLlLVTYFX0Htp1vL4L722')
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
    let(:headers) do
      { 'CONTENT_TYPE' => 'application/json' }
    end
    let(:params) do
      {
        'id': 'evt_1CiPtv2eZvKYlo2CcUZsDcO6',
        'object': 'event',
        'api_version': '2018-05-21',
        'created': 1530291411,
        'type': 'setup_intent.setup_failed',
        'data': {
          'object': setup_intent
        }
      }
    end
    let(:setup_intent) do
      {
        'id': 'seti_1KEYLbLVTYFX0HtpreRhfh0q',
        'object': 'setup_intent',
        'application': nil,
        'cancellation_reason': nil,
        'client_secret': 'seti_1KErxRLVTYFX0HtpRXB6lAR4_secret_KuhM8kUrpSo5ukBGrM88J2ByyrKWVUn',
        'created': 1641460109,
        'customer': 'cus_KuN5JMXAs5rOM8',
        'description': nil,
        'last_setup_error': {
          'code': 'payment_method_microdeposit_verification_attempts_exceeded',
          'doc_url': 'https://stripe.com/docs/error-codes/payment-method-microdeposit-verification-attempts-exceeded',
          'message': 'You have exceeded the number of allowed verification attempts.',
          'payment_method': {
            'id': payment_method_id,
            'object': 'payment_method',
            'acss_debit': {
              'bank_name': 'STRIPE TEST BANK',
              'fingerprint': 'DEVrZYsxRxNXrufb',
              'institution_number': '000', 'last4': '2227', 'transit_number': '11000'
            },
            'billing_details': {},
            'created': 1641460230,
            'customer': nil,
            'livemode': false,
            'metadata': {},
            'type': 'acss_debit'
          },
          'type': 'invalid_request_error'
        },
        'latest_attempt': 'setatt_1KEYLoLVTYFX0HtpwX5UO9B4',
        'livemode': false,
        'mandate': 'mandate_1KEYLoLVTYFX0HtpC9w3dUiB',
        'metadata': {},
        'next_action': nil,
        'on_behalf_of': nil,
        'payment_method': nil,
        'payment_method_options': {
          'acss_debit': {
            'currency': 'cad',
            'mandate_options': {
              'interval_description': 'on the 15th of every month, starting Jan 2022',
              'payment_schedule': 'interval',
              'transaction_type': 'personal'
            },
          'verification_method': 'automatic'
          }
        },
        'payment_method_types': ['acss_debit'],
        'single_use_mandate': nil,
        'status': 'requires_payment_method',
        'usage': 'off_session'
      }
    end
    let(:payment_method_id) { payment_method.payment_processor_source_id }
    let!(:payment_method) { create(:payment_method, :acss_debit) }

    it 'destroys the corresponding payment method' do
      expect {
        post webhook_path, params: params.to_json, headers: headers
      }.to change { PaymentMethod.count }.by(-1)

      expect(response).to have_http_status(:success)
      expect(PaymentMethod.find_by(id: payment_method_id)).to be_nil
    end
  end
end
