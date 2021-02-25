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

  def webhook
    event = nil
    payload = request.body.read

    begin
      event = Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
    rescue JSON::ParserError => e
      head 400
    end

    case event.type
    when 'charge.failed'
      head handle_payment_failed(payment: event.data.object, event_type: 'charge')
    when 'payment_intent.payment_failed'
      head handle_payment_failed(payment: event.data.object, event_type: 'payment_intent')
    when 'charge.succeeded', 'payment_intent.succeeded'
      head handle_payment_success(payment: event.data.object)
    end
  end

  private

  def handle_payment_failed(payment:, event_type:)
    contribution_id = payment[:metadata][:contribution_id]

    return 400 unless contribution_id.present?

    contribution = Contribution.find_by(id: contribution_id)
    errors = if event_type == 'charge'
               { error_code: payment[:failure_code], error_message: payment[:failure_message] }.to_json
             else
               { error_code: payment[:last_payment_error][:code], error_message: payment[:last_payment_error][:message] }.to_json
             end

    outcome = Contributions::ProcessContributionPaymentFailed.run(contribution: contribution, errors: errors)

    outcome.success? ? 200 : 400
  end

  def handle_payment_success(payment:)
    contribution_id = payment[:metadata][:contribution_id]

    return 400 unless contribution_id.present?

    contribution = Contribution.find_by(id: contribution_id)

    outcome = Contributions::ProcessContributionPaymentSucceeded.run(contribution: contribution, receipt: payment.to_json)

    outcome.success? ? 200 : 400
  end
end
