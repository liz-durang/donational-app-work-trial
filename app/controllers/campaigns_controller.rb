# frozen_string_literal: true

class CampaignsController < ApplicationController
  protect_from_forgery unless: -> { request.format.js? }

  before_action :ensure_donor_has_permission!, except: %i[show donation_box]

  layout 'embeddable', only: :donation_box

  def index
    @view_model = OpenStruct.new(partner: partner)
  end

  def show
    not_found unless campaign

    @view_model = OpenStruct.new(
      partner_name: partner.name,
      partner_description: partner.description,
      partner_website_url: partner.website_url,
      partner_logo: partner.logo,
      banner_image: campaign.banner_image,
      campaign_title: campaign.title,
      campaign_slug: campaign.slug,
      campaign_description: campaign.description,
      contribution_amount_help_text: campaign.contribution_amount_help_text,
      donation_frequencies: campaign.allowable_donation_frequencies,
      default_contribution_amounts: campaign.default_contribution_amounts,
      campaign_contributions_path: campaign_contributions_path(campaign.slug),
      new_campaign_contribution: new_campaign_contribution,
      managed_portfolios: managed_portfolios,
      donor_questions: partner.donor_questions,
      default_operating_costs_donation_percentages: partner.default_operating_costs_donation_percentages,
      partner_operating_costs_text: partner.operating_costs_text,
      partner_accepts_operating_costs_donations?: partner.accepts_operating_costs_donations?,
      currency: partner_currency
    )

    respond_to do |format|
      format.js
      format.html do
        allow_iframe_embedding_on_partner_website!
      end
    end
  end

  def new
    @view_model = OpenStruct.new(
      partner: partner,
      campaign: Campaign.new,
      currency: partner_currency
    )
  end

  def edit
    @view_model = OpenStruct.new(
      partner: partner,
      campaign: campaign_by_id,
      banner_image: campaign_by_id.banner_image,
      default_contribution_amounts: campaign_by_id.default_contribution_amounts.join(', '),
      currency: partner_currency
    )
  end

  def create
    command = Campaigns::CreateCampaign.run(
      partner: partner,
      title: params[:title],
      description: params[:description],
      slug: params[:slug],
      banner_image: params[:banner_image],
      default_contribution_amounts: default_contribution_amounts,
      contribution_amount_help_text: params[:contribution_amount_help_text].presence,
      allow_one_time_contributions: params[:allow_one_time_contributions]
    )

    flash[:success] = 'Campaign created successfully.' if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to partner_campaigns_path(partner)
  end

  def update
    command = Campaigns::UpdateCampaign.run(
      campaign: campaign_by_id,
      title: params[:title],
      description: params[:description],
      slug: params[:slug],
      banner_image: params[:banner_image],
      default_contribution_amounts: default_contribution_amounts,
      contribution_amount_help_text: params[:contribution_amount_help_text].presence,
      allow_one_time_contributions: params[:allow_one_time_contributions]
    )

    flash[:success] = 'Campaign updated successfully.' if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to edit_partner_campaign_path(partner, campaign_by_id)
  end

  def donation_box
    not_found unless campaign

    @view_model = OpenStruct.new(
      partner_name: partner.name,
      partner_description: partner.description,
      partner_website_url: partner.website_url,
      partner_logo: partner.logo,
      banner_image: campaign.banner_image,
      campaign_title: campaign.title,
      campaign_slug: campaign.slug,
      campaign_description: campaign.description,
      contribution_amount_help_text: campaign.contribution_amount_help_text,
      donation_frequencies: campaign.allowable_donation_frequencies,
      default_contribution_amounts: campaign.default_contribution_amounts,
      campaign_contributions_path: campaign_contributions_path(campaign.slug),
      new_campaign_contribution: new_campaign_contribution,
      managed_portfolios: managed_portfolios,
      donor_questions: partner.donor_questions,
      default_operating_costs_donation_percentages: partner.default_operating_costs_donation_percentages,
      partner_operating_costs_text: partner.operating_costs_text,
      partner_accepts_operating_costs_donations?: partner.accepts_operating_costs_donations?,
      currency: partner_currency
    )

    respond_to do |format|
      format.js
      format.html do
        allow_iframe_embedding_on_partner_website!
      end
    end
  end

  private

  def ensure_donor_has_permission!
    unless current_donor.partners.exists?(id: partner.id)
      flash[:error] = "Sorry, you don't have permission to create a campaign for this partner"
      redirect_to edit_partner_path(partner)
    end
  end

  def allow_iframe_embedding_on_partner_website!
    response.headers['X-Content-Security-Policy'] = "frame-ancestors #{partner.website_url}"
    response.headers['Content-Security-Policy'] = "frame-ancestors #{partner.website_url}"
    response.headers.delete 'X-Frame-Options'
  end

  def new_campaign_contribution
    CampaignContribution.new(
      first_name: current_donor.try(:first_name),
      last_name: current_donor.try(:last_name),
      email: current_donor.try(:email)
    )
  end

  def partner_currency
    currency = partner.currency
    Money::Currency.new(currency)
  end

  def campaign
    @campaign ||= Partners::GetCampaignBySlug.call(slug: params[:campaign_slug].parameterize)
  end

  def campaign_by_id
    @campaign_by_id ||= Partners::GetCampaignById.call(id: params[:id])
  end

  def partner
    @partner = Partners::GetPartnerById.call(id: params[:partner_id]) || campaign.partner
  end

  def donor_partner
    Partners::GetPartnerForDonor.call(donor: current_donor)
  end

  def default_contribution_amounts
    params[:default_contribution_amounts].split(',').map(&:to_i)
  end

  def managed_portfolios
    Partners::GetManagedPortfoliosForPartner.call(partner: partner)
  end
end
