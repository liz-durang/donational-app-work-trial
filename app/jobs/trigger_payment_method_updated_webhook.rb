class TriggerPaymentMethodUpdatedWebhook < ApplicationJob

  def perform(donor_id)
    donor = Donors::GetDonorById.call(id: donor_id)
    current_partner = Partners::GetPartnerForDonor.call(donor: donor)

    if ensure_partner_has_webhook(current_partner)
      base_url = current_partner.zapier_webhooks.find_by(hook_type: 'update_payment_method').hook_url

      conn = Faraday.new(url: base_url) do |faraday|
        faraday.headers['X-Api-Key'] = current_partner.api_key
        faraday.adapter Faraday.default_adapter
      end

      if Contributions::GetActiveSubscription.call(donor: donor).present?
        subscription_id = Contributions::GetActiveSubscription.call(donor: donor).id
      else
        subscription_id = nil
      end

      response = conn.post() do |req|
        req.body = {
          updated_at: Time.zone.now,
          subscription_id: subscription_id,
          donor: {
            id: donor.id,
            name: donor.name,
            first_name: donor.first_name,
            last_name: donor.last_name,
            email: donor.email,
          }
        }.to_json
      end

      raise unless response.status == 200 || response.status == 410
    end
  end

  private

  def ensure_partner_has_webhook(current_partner)
    Hooks::GetZapierWebhookByType.call(partner: current_partner, hook_type: 'update_payment_method').present?
  end
end
