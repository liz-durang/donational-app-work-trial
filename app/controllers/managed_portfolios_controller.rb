class ManagedPortfoliosController < ApplicationController
  before_action :ensure_donor_has_permission!

  def index
    @view_model = OpenStruct.new(partner: partner)
  end

  def new
    @view_model = OpenStruct.new(partner: partner)
  end

  def edit
    @view_model = OpenStruct.new(
      partner: partner,
      managed_portfolio: managed_portfolio,
      image: managed_portfolio.image,
      managed_portfolio_path: partner_managed_portfolio_path
    )
  end

  def create
    command = Portfolios::CreateManagedPortfolio.run(
      partner: partner,
      donor: current_donor,
      title: params[:title],
      description: params[:description].presence,
      featured: params[:featured].presence,
      image: params[:image],
      charities: organizations
    )

    if command.success?
      flash[:success] = "Portfolio created successfully." 
      redirect_to edit_partner_managed_portfolio_path(id: command.result)
    else
      flash[:error] = command.errors.message_list.join('. ') unless command.success?
      redirect_to new_partner_managed_portfolio_path
    end
  end

  def update
    command = Portfolios::UpdateManagedPortfolio.run(
      managed_portfolio: managed_portfolio,
      donor: current_donor,
      title: params[:title],
      description: params[:description].presence,
      featured: params[:featured].presence,
      image: params[:image],
      organizations: organizations
    )

    flash[:success] = "Portfolio updated successfully." if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to edit_partner_managed_portfolio_path(partner, managed_portfolio)
  end

  def order
    ManagedPortfolio.transaction do
      params[:managed_portfolio_ids_in_display_order].each_with_index do |id, index|
        ManagedPortfolio.where(id: id).update(display_order: index)
      end
    end
  end

  private

  def ensure_donor_has_permission!
    unless current_donor.partners.exists?(id: partner.id)
      flash[:error] = "Sorry, you don't have permission to create a portfolio for this partner."
      redirect_to new_partner_managed_portfolio_path(partner)
    end
  end

  def partner
    @partner = Partners::GetPartnerById.call(id: params[:partner_id])
  end

  def managed_portfolio
    @managed_portfolio = Partners::GetManagedPortfolioById.call(id: params[:id])
  end

  def organizations
    params[:charities].split(';')
  end
end
