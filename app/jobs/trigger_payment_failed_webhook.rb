class TriggerPaymentFailedWebhook < ApplicationJob

  def perform(contribution_id, partner_id)
    current_partner = Partners::GetPartnerById.call(id: partner_id)
    contribution = Contributions::GetContributionById.call(id: contribution_id)

    donor = contribution.donor

    if ensure_partner_has_webhook(current_partner)
      subscription = Contributions::GetActiveSubscription.call(donor: donor) || Contributions::GetLastDeactivatedSubscription.call(donor: donor)

      base_url = current_partner.zapier_webhooks.find_by(hook_type: 'payment_failed').hook_url

      conn = Faraday.new(url: base_url) do |faraday|
        faraday.headers['X-Api-Key'] = current_partner.api_key
        faraday.adapter Faraday.default_adapter
      end

      affiliation = Partners::GetPartnerAffiliationByDonorAndPartner.call(
        donor: donor,
        partner: current_partner
      )

      portfolio_name = contribution.portfolio.managed_portfolio.try(:name) || 'Custom Portfolio'
      subscription_portfolio_name = subscription.portfolio.managed_portfolio.try(:name) || 'Custom Portfolio'

      response = conn.post() do |req|
        req.body = {
          contribution: {
            id: contribution.id,
            created_at: contribution.created_at,
            scheduled_at: contribution.scheduled_at,
            failed_at: contribution.failed_at,
            partner_contribution_percentage: contribution.partner_contribution_percentage,
            portfolio: portfolio_name
          },
          subscription: {
            id: subscription.id,
            start_at: subscription.start_at.to_date,
            frequency: subscription.frequency,
            amount_dollars: subscription.amount_dollars,
            partner_contribution_percentage: subscription.partner_contribution_percentage,
            portfolio: subscription_portfolio_name
          },
          donor: {
            id: donor.id,
            name: donor.name,
            first_name: donor.first_name,
            last_name: donor.last_name,
            email: contribution.donor_email,
            joined_at: contribution.donor.created_at,
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
      Hooks::GetZapierWebhookByType.call(partner: current_partner, hook_type: 'payment_failed').present?
  end
end
