class CampaignsController < ApplicationController
  layout 'minimal'

  def show
    not_found unless campaign

    @view_model = OpenStruct.new(
      partner_name: partner.name,
      partner_description: partner.description,
      partner_website_url: partner.website_url,
      campaign_title: campaign.title,
      campaign_description: campaign.description,
      default_contribution_amounts: campaign.default_contribution_amounts,
      campaign_contributions_path: campaign_contributions_path(campaign.slug),
      new_campaign_contribution: new_campaign_contribution,
      portolio_templates: partner.portfolio_templates
    )
  end

  private

  def new_campaign_contribution
    CampaignContribution.new(
      first_name: current_donor.try(:first_name),
      last_name: current_donor.try(:last_name),
      email: current_donor.try(:email)
    )
  end

  def campaign
    @campaign ||= Partners::GetCampaignBySlug.call(slug: params[:campaign_slug])
  end

  def partner
    @partner ||= campaign.partner
  end
end
