module Api
  module V1
    class OrganizationsController < Api::V1::ApiController
      def index
        @organizations = SearchableOrganization.search_for(search_params).select(:ein, :name, :state).limit(10)
      end

      def show
        @organization = SearchableOrganizations::GetSearchableOrganizationByEin.call(ein: lookup_params)
        render json: { error: "Could not find an organization with EIN #{lookup_params}" }, status: :not_found unless @organization.present?
      end

      private

      def search_params
        params[:name]
      end

      def lookup_params
        params[:id]
      end
    end
  end
end
