class SearchableOrganizationsController < ApplicationController
  include Secured

  def index
    @organizations = SearchableOrganization.search_for(params[:name])
    respond_to do |format|
      format.html { render partial: 'searchable_organizations/managed_portfolio' } if params[:from] == 'portfolios'
      format.html { render partial: 'searchable_organizations/allocations' } if params[:from] == 'allocations'
    end
  end
end
