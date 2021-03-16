module Partners
  class ContributionsController < ApplicationController
    include Secured
    include ClientSideAnalytics
    before_action :ensure_donor_has_permission!

    def create
      pipeline = Flow.new
      pipeline.chain { update_subscription! }

      outcome = pipeline.run

      if outcome.success?
        track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })
        flash[:success] = "We've updated your donation plan"
        redirect_to edit_partner_donor_path(partner, donor)
      else
        redirect_to edit_partner_donor_path(partner, donor), alert: outcome.errors.message_list.join('\n')
      end
    end

    def destroy
      Contributions::DeactivateSubscription.run(subscription: active_subscription)

      flash[:success] = "We've cancelled the donation plan"
      redirect_to edit_partner_donor_path(partner, donor)
    end

    private

    def ensure_donor_has_permission!
      unless current_donor.partners.exists?(id: partner.id)
        flash[:error] = "Sorry, you don't have permission to modify this contribution."
        redirect_to edit_partner_donor_path(partner, donor)
      end
    end

    def tips_options
      [0, 200, 500, 1000].map do |amount|
        [
          amount,
          Money.new(amount, current_currency).format(no_cents_if_whole: true, display_free: 'No tip')
        ]
      end
    end

    def update_subscription!
      Contributions::CreateOrReplaceSubscription.run(
        donor: donor,
        portfolio: Portfolio.find(portfolio_id),
        partner: partner,
        frequency: frequency,
        amount_cents: amount_cents,
        tips_cents: tips_cents,
        start_at: start_at,
        partner_contribution_percentage: 0,
        trial_amount_cents: trial_amount_cents
      )
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:id]) || Donors::GetDonorById.call(id: params[:subscription][:donor_id])
    end

    def payment_method
      @payment_method = Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def active_portfolio
      @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: donor)
    end

    def active_subscription
      @active_subscription ||= Contributions::GetActiveSubscription.call(donor: donor)
    end

    def partner_affiliation
      @partner_affiliation ||= Partners::GetPartnerAffiliationByDonor.call(donor: donor)
    end

    def partner
      @partner ||= Partners::GetPartnerForDonor.call(donor: donor)
    end

    def managed_portfolio?
      Portfolios::GetPortfolioManager.call(portfolio: active_portfolio).present?
    end

    def selectable_portfolios
      portfolios = []
      portfolios << [active_portfolio.id, 'My personalized portfolio'] if active_portfolio && !managed_portfolio?
      portfolios += Partners::GetManagedPortfoliosForPartner.call(partner: partner).pluck(:portfolio_id, :name) if partner
      portfolios
    end

    def new_subscription
      Subscription.new(
        donor: donor,
        amount_cents: target_amount_cents,
        portfolio: active_portfolio,
        frequency: donor.contribution_frequency
      )
    end

    def target_amount_cents
      Contributions::GetTargetContributionAmountCents.call(
        donor: donor,
        frequency: active_subscription.try(:frequency) || donor.contribution_frequency
      )
    end

    def amount_cents
      amount_dollars * 100
    end

    def tips_cents
      params[:subscription][:tips_cents].to_i
    end

    def amount_dollars
      params[:subscription][:amount_dollars].to_i
    end

    def trial_amount_cents
      trial_amount_dollars * 100
    end

    def trial_amount_dollars
      params[:subscription][:trial_amount_dollars].to_i
    end

    def payment_token
      params[:subscription][:payment_token]
    end

    def frequency
      params[:subscription][:frequency]
    end

    def portfolio_id
      params[:subscription][:portfolio_id]
    end

    def start_at
      start_at_param = params.dig(:subscription, :start_at)
      Time.zone.parse(start_at_param) if start_at_param
    end
  end
end
