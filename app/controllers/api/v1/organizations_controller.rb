module Api
  module V1
    class OrganizationsController < Api::V1::ApiController
      skip_before_action :authenticate_partner!

      def index
        @organizations = SearchableOrganization.search_for(search_params)
      end

      def show
        @organization = SearchableOrganizations::GetSearchableOrganizationByEin.call(ein: lookup_params)
        unless @organization.present?
          render_errors({ organization: "Could not find an organization with EIN #{lookup_params}" }, :not_found)
        end
      end

      private

      def search_params
        params[:name]
      end

      def lookup_params
        params[:id].delete('-')
      end
    end
  end
end
