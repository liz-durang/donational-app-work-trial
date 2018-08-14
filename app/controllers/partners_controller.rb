class PartnersController < ApplicationController
  include Secured

  before_action :ensure_donor_has_permission!, except: :account_connection

  def update
    pipeline = Flow.new
    pipeline.chain { update_partner! } if params[:partner].present?
    pipeline.chain { create_or_update_question! } if params[:name].present?
    pipeline.chain { delete_question! } if params[:question].present?

    outcome = pipeline.run

    if outcome.success?
      flash[:success] = "Thanks, we've updated your information" if params[:partner].present?
      flash[:success] = "Question was added successfully" if params[:name].present?
      flash[:success] = "Question was deleted successfully" if params[:question].present?
    else
      flash[:error] = outcome.errors.message_list.join('. ')
    end

    redirect_to edit_partner_path(partner)
  end

  def edit
    @view_model = OpenStruct.new(
      donor: current_donor,
      partner: partner,
      partner_path: partner_path,
      stripe_connect_url: stripe_connect_url
    )
  end

  def account_connection
    if params[:error].present?
      flash[:error] = params[:error_description]
    else
      Payments::ConnectPartnerAccount.run(
        partner: partner,
        authorization_code: params[:code]
      )

      flash[:success] = "Thanks, your Stripe account was connected successfully"
    end

    redirect_to edit_partner_path(partner)
  end

  private

  def ensure_donor_has_permission!
    unless current_donor.partners.exists?(id: partner.id)
      flash[:error] = "Sorry, you don't have permission to update this partner account"
      redirect_to edit_partner_path(partner)
    end
  end

  def partner
    # Partner ID from Stripe response is retrieved as params[:state]
    id = params[:id] || params[:state]
    @partner ||= Partners::GetPartnerById.call(id: id)
  end

  def stripe_connect_url
    "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=" + ENV.fetch('STRIPE_CLIENT_ID') + "&scope=read_write&state=" + partner.id
  end

  def update_partner!
    Partners::UpdatePartner.run(
      partner: partner,
      name: params[:partner][:name],
      website_url: params[:partner][:website_url],
      description: params[:partner][:description],
      logo: params[:partner][:logo]
    )
  end

  def create_or_update_question!
    command = Partners::CreateOrUpdateCustomDonorQuestion.run(
      partner: partner,
      name: params[:name],
      title: params[:title],
      type: params[:type].downcase,
      options: params[:options].gsub(' ,', ',').split(','),
      required: params[:required]
    )
  end

  def delete_question!
    command = Partners::DeleteCustomDonorQuestion.run(
      partner: partner,
      name: params[:question]
    )
  end
end
