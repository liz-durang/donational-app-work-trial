class TriggerSubscriptionUpdatedWebhook < ApplicationJob

  def perform(subscription_id, partner_id)
    current_partner = Partners::GetPartnerById.call(id: partner_id)

    if ensure_partner_has_webhook(current_partner)
      subscription = Contributions::GetSubscriptionById.call(id: subscription_id)

      donor = subscription.donor

      base_url = current_partner.zapier_webhooks.find_by(hook_type: 'update_recurring_contribution').hook_url

      conn = Faraday.new(url: base_url) do |faraday|
        faraday.headers['X-Api-Key'] = current_partner.api_key
        faraday.adapter Faraday.default_adapter
      end

      affiliation = Partners::GetPartnerAffiliationByDonorAndPartner.call(
        donor: donor,
        partner: current_partner
      )

      portfolio_name = subscription.portfolio.managed_portfolio.try(:name) || 'Custom Portfolio'

      response = conn.post() do |req|
        req.body = {
          id: subscription.id,
          updated_at: subscription.updated_at,
          start_at: subscription.start_at.to_date,
          frequency: subscription.frequency,
          amount_dollars: subscription.amount_dollars,
          donor_name: subscription.donor_name,
          donor_email: subscription.donor_email,
          partner_contribution_percentage: subscription.partner_contribution_percentage,
          portfolio: portfolio_name,
          donor: {
            id: donor.id,
            name: donor.name,
            first_name: donor.first_name,
            last_name: donor.last_name,
            email: subscription.donor_email,
            joined_at: subscription.donor.created_at,
            questions: affiliation.donor_responses.map { |r| [r.question.name, r.value]  }.to_h,
            campaign: affiliation.campaign_title,
            partner: affiliation.partner_name
          }
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
