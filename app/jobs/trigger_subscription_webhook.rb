class TriggerSubscriptionWebhook < ApplicationJob
  def perform(action, partner_id, subscription_id)
    partner = Partners::GetPartnerById.call(id: partner_id)
    hook = Hooks::GetZapierWebhookByType.call(partner: partner, hook_type: hook_type(action))

    return unless hook.present?

    subscription = Contributions::GetSubscriptionById.call(id: subscription_id)
    donor = subscription.donor
    portfolio_name = subscription.portfolio.managed_portfolio.try(:name) || 'Custom Portfolio'
    base_url = hook.hook_url

    conn = Faraday.new(url: base_url) do |faraday|
      faraday.headers['X-Api-Key'] = partner.api_key
      faraday.adapter Faraday.default_adapter
    end

    affiliation = Partners::GetPartnerAffiliationByDonorAndPartner.call(
      donor: donor,
      partner: partner
    )

    response = conn.post() do |req|
      body = {
        id: subscription.id,
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
          questions: affiliation.donor_responses.map { |r| [r.question.name, r.value] }.to_h,
          campaign: affiliation.campaign_title,
          partner: affiliation.partner_name
        }
      }

      if subscription.trial_active? && create_or_update?(action)
        body[:trial_start_at] = subscription.trial_start_at
        body[:trial_amount_dollars] = subscription.trial_amount_dollars
      end

      body[:updated_at] = subscription.updated_at if create_or_update?(action)

      body[:cancelled_at] = subscription.deactivated_at if action == :cancel
      body[:trial_cancelled_at] = subscription.trial_deactivated_at if action == :cancel_trial

      req.body = body.to_json
    end

    raise unless response.status == 200 || response.status == 410
  end

  private

  def create_or_update?(action)
    action == :create || action == :update
  end

  def hook_type(action)
    case action
    when :cancel, :cancel_trial
      'cancel_recurring_contribution'
    when :create
      'create_recurring_contribution'
    when :update
      'update_recurring_contribution'
    end
  end
end
