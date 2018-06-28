class CampaignsController < ApplicationController
  before_action :ensure_donor_has_permission!, except: :show

  def create
    command = Campaigns::CreateCampaign.run(
      partner: current_donor.partners.first,
      title: params[:title],
      description: params[:description],
      slug: params[:slug],
      default_contribution_amounts: default_contribution_amounts
    )

    flash[:success] = "Campaign created successfully." if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to new_partner_campaigns_path(partner)
  end

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
      portolio_templates: partner.portfolio_templates,
      donor_questions: partner.donor_questions
    )
  end

  private

  def ensure_donor_has_permission!
    unless current_donor.partners.exists?(id: partner.id)
      flash[:error] = "Sorry, you don't have permission to create a campaign for this partner"
      redirect_to edit_partner_path(partner)
    end
  end

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
    @partner = Partners::GetPartnerById.call(id: params[:partner_id]) || campaign.partner
  end

  def default_contribution_amounts
    params[:default_contribution_amounts].split(',').map { |amount| amount.to_i }
  end
end
