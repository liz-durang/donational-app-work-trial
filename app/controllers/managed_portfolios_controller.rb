class ManagedPortfoliosController < ApplicationController
  before_action :ensure_donor_has_permission!

  def create
    command = Portfolios::CreateManagedPortfolio.run(
      partner: partner,
      donor: current_donor,
      title: params[:title],
      description: params[:description],
      charities: organizations
    )

    flash[:success] = "Portfolio created successfully." if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to new_partner_managed_portfolio_path(partner)
  end

  def update
    command = Portfolios::UpdateManagedPortfolio.run(
      managed_portfolio: managed_portfolio,
      donor: current_donor,
      title: params[:title],
      description: params[:description],
      charities: organizations
    )

    flash[:success] = "Portfolio edited successfully." if command.success?
    flash[:error] = command.errors.message_list.join('. ') unless command.success?
    redirect_to edit_partner_managed_portfolio_path(partner, managed_portfolio)
  end

  def edit
    @view_model = OpenStruct.new(
      managed_portfolio: managed_portfolio,
      managed_portfolio_path: partner_managed_portfolio_path
    )
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
    params[:charities].split('|')
  end
end
