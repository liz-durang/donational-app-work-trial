class ProfilesController < ApplicationController
  def show
    not_found and return unless donor

    @view_model = OpenStruct.new(
      donor: donor,
      organizations: organizations,
      new_profile_contribution: ProfileContribution.new,
      portfolio_id: active_portfolio.id,
      link_token: Payments::GeneratePlaidLinkToken.call(donor_id: SecureRandom.uuid),
      show_plaid?: partner.supports_plaid?,
      currency: partner_currency,
      default_contribution_amounts: default_contribution_amounts,
      minimum_contribution_amount: minimum_contribution_amount,
      donation_frequencies: donation_frequencies
    )
  end

  private

  def donor
    @donor ||= Donors::GetDonorByUsername.call(username: params[:username])
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: donor)
  end

  def allocations
    @allocations ||= Portfolios::GetActiveAllocations.call(portfolio: active_portfolio)
  end

  def organizations
    @organizations ||= allocations.map(&:organization)
  end

  def partner
    @partner ||= Partners::GetPartnerForDonor.call(donor: donor)
  end

  def partner_affiliation
    @partner_affiliation ||= Partners::GetPartnerAffiliationByDonor.call(donor: donor)
  end

  def campaign
    @campaign ||= partner_affiliation.campaign
  end

  def default_contribution_amounts
    @default_contribution_amounts ||= campaign.present? ? campaign.default_contribution_amounts : [10, 20, 50, 100]
  end

  def minimum_contribution_amount
    @minimum_contribution_amount ||= campaign.present? ? campaign.minimum_contribution_amount : 10
  end

  def donation_frequencies
    Subscription.frequency.options.select { |_k, v| v.in? %w[once monthly] }
  end

  def partner_currency
    currency = partner.currency
    Money::Currency.new(currency)
  end
end
