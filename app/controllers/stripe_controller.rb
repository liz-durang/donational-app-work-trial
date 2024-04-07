class StripeController < ApplicationController
  protect_from_forgery unless: -> { request.format.js? }, except: :webhook

  def get_setup_intent_client_secret
    client_secret = Payments::GenerateSetupIntentClientSecret.call

    if client_secret
      render json: { client_secret: client_secret }
    else
      render json: { status: 500 }
    end
  end

  def get_acss_client_secret
    client_secret, customer_id = if current_donor
      Payments::GenerateAcssClientSecretForDonor.call(donor: current_donor)
    else
      setup_params = params.permit(:email, :frequency, :start_at_month, :start_at_year, :trial).to_h.symbolize_keys
      partner = Partner.find(params[:partner_id])
      Payments::GenerateAcssClientSecret.call(**setup_params.merge(account_id: partner.payment_processor_account_id))
    end

    if client_secret
      render json: { client_secret: client_secret, customer_id: customer_id }
    else
      render json: { status: 500 }
    end
  end

  def webhook
    event = nil
    payload = request.body.read

    begin
      event = Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
    rescue JSON::ParserError => e
      head :bad_request
      return
    end

    response = case event.type
               when 'charge.failed'
                 handle_payment_failed(payment: event.data.object)
               when 'charge.succeeded'
                 if event.data.object.payment_method_details.type.in? %w[acss_debit bacs_debit]
                   handle_acss_or_bacs_payment_success(event:)
                 else
                   handle_payment_success(payment: event.data.object)
                 end
               when 'charge.dispute.created'
                 handle_dispute_created(event:)
               when 'setup_intent.succeeded'
                 handle_verification_success(setup_intent: event.data.object)
               when 'setup_intent.setup_failed'
                 handle_verification_failed(setup_intent: event.data.object)
               else
                 200
               end

    head response
  end

  private

  def handle_payment_failed(payment:)
    contribution_id = payment[:metadata][:contribution_id]

    return 200 unless contribution_id.present?

    contribution = Contribution.find_by(id: contribution_id)
    errors = { error_code: payment[:failure_code], error_message: payment[:failure_message] }.to_json

    outcome = Contributions::ProcessContributionPaymentFailed.run(contribution: contribution, errors: errors)

    outcome.success? ? 200 : 400
  end

  def handle_payment_success(payment:)
    contribution_id = payment[:metadata][:contribution_id]

    return 200 unless contribution_id.present?

    contribution = Contribution.find_by(id: contribution_id)

    outcome = Contributions::ProcessContributionPaymentSucceeded.run(contribution: contribution, receipt: payment.to_json)

    outcome.success? ? 200 : 400
  end

  def handle_acss_or_bacs_payment_success(event:)
    charge = event.data.object
    account_id = event.account
    outcome = Contributions::ProcessContributionAcssOrBacsPaymentSucceeded.run(charge: charge, account_id: account_id)
    outcome.success? ? 200 : 400
  end

  def handle_verification_success(setup_intent:)
    payment_method = Payments::GetPaymentMethodBySourceId.call(source_id: setup_intent[:payment_method])
    return 400 unless payment_method.present?
    return 200 unless payment_method.type == 'PaymentMethods::AcssDebit'

    partner_account_id = Payments::GetPaymentProcessorAccountId.call(donor: payment_method.donor)
    outcome = Payments::UpdateCustomerAcssDebitDetails.run(
      customer_id: setup_intent[:customer],
      payment_method_id: setup_intent[:payment_method],
      donor_id: payment_method.donor_id,
      account_id: partner_account_id
    )

    outcome.success? ? 200 : 400
  end

  def handle_verification_failed(setup_intent:)
    Rails.logger.warn("Stripe webhook `setup_intent.setup_failed`: #{setup_intent[:customer]}")

    case setup_intent[:status]
    when 'requires_payment_method'
      Rails.logger.info("Error code: #{setup_intent[:last_setup_error][:code]}. Deleting payment method: #{setup_intent[:last_setup_error][:payment_method][:id]}")
      outcome = Payments::DeletePaymentMethodBySourceId.run(source_id: setup_intent[:last_setup_error][:payment_method][:id])
      outcome.success? ? 200 : 400
    else
      Rails.logger.info("Unhandled `setup_intent.setup_failed` status: #{setup_intent[:status]}, error: #{setup_intent[:last_setup_error][:code]}")
    end

    200
  end

  def handle_dispute_created(event:)
    dispute = event.data.object
    account_id = event.account
    Rails.logger.info("Stripe webhook `charge.dispute.created`. Account: #{account_id}, charge: #{dispute[:charge]}")

    charge = Payments::GetChargeFromDispute.call(account_id: account_id, charge_id: dispute[:charge])
    return 400 unless charge.present?

    contribution_id = charge[:metadata][:contribution_id]
    return 400 unless contribution_id.present?

    outcome = Contributions::DisputeContribution.run(contribution_id: contribution_id)
    outcome.success? ? 200 : 400
  end
end
