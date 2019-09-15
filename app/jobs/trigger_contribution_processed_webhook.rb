class TriggerContributionProcessedWebhook < ApplicationJob

  def perform(contribution_id, partner_id)
    current_partner = Partners::GetPartnerById.call(id: partner_id)

    if ensure_partner_has_webhook(current_partner)
      contribution = Contributions::GetContributionById.call(id: contribution_id)

      base_url = current_partner.zapier_webhooks.find_by(hook_type: 'process_contribution').hook_url

      conn = Faraday.new(url: base_url) do |faraday|
        faraday.headers['X-Api-Key'] = current_partner.api_key
        faraday.adapter Faraday.default_adapter
      end

      response = conn.post() do |req|
        req.body = contribution.slice('donor_id', 'processed_at', 'amount_dollars').to_json
      end

      raise unless response.status == 200 || response.status == 410
    end
  end

  private

  def ensure_partner_has_webhook(current_partner)
      Hooks::GetZapierWebhookByType.call(partner: current_partner, hook_type: 'process_contribution').present?
  end
end
