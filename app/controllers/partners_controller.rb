class PartnersController < ApplicationController
  include Secured

  def update
    command = Partners::UpdatePartner.run(
      partner: partner,
      name: params[:partner][:name],
      website_url: params[:partner][:website_url],
      description: params[:partner][:description]
    )

    if command.success?
      flash[:success] = "Thanks, we've updated your information"
      redirect_to edit_partners_path
    else
      flash[:error] = command.errors.message_list.join('. ')
      redirect_to edit_partners_path
    end
  end

  def edit
    @view_model = OpenStruct.new(
      donor: current_donor,
      partner: partner,
      partners_path: partners_path
    )
  end

  private

  def partner
    @partner ||= current_donor.partners.first
  end
end
