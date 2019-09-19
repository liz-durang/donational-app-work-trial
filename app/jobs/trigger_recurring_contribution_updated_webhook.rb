class TriggerRecurringContributionUpdatedWebhook < ApplicationJob

  def perform(recurring_contribution_id, partner_id)
    current_partner = Partners::GetPartnerById.call(id: partner_id)

    if ensure_partner_has_webhook(current_partner)
      recurring_contribution = Contributions::GetRecurringContributionById.call(id: recurring_contribution_id)

      base_url = current_partner.zapier_webhooks.find_by(hook_type: 'update_recurring_contribution').hook_url

      conn = Faraday.new(url: base_url) do |faraday|
        faraday.headers['X-Api-Key'] = current_partner.api_key
        faraday.adapter Faraday.default_adapter
      end

      response = conn.post() do |req|
        req.body = {
          id: recurring_contribution.id,
          start_at: recurring_contribution.start_at.to_date,
          frequency: recurring_contribution.frequency,
          amount_dollars: recurring_contribution.amount_dollars,
          donor_name: recurring_contribution.donor_name,
          donor_email: recurring_contribution.donor_email
        }.to_json
      end

      raise unless response.status == 200 || response.status == 410
    end
  end

  private

  def ensure_partner_has_webhook(current_partner)
      Hooks::GetZapierWebhookByType.call(partner: current_partner, hook_type: 'update_recurring_contribution').present?
  end
end
