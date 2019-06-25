module Api
  module V1
    class OrganizationsController < Api::V1::ApiController
      def index
        @organizations = SearchableOrganization.search_for(search_params).select(:ein, :name, :state).limit(10)
      end

      private

      def search_params
        params[:name]
      end
    end
  end
end
