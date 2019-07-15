module Api
  module V1
    class PortfoliosController < Api::V1::ApiController
      def index
        @managed_portfolios = current_partner.managed_portfolios
      end
    end
  end
end
