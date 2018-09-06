module Api
  module V1
    class ApiController < ActionController::Base
      helper_method :current_partner
      before_action :authenticate_partner!
      before_action :check_json_request
      skip_before_action :verify_authenticity_token

      layout false

      rescue_from Exception,                           with: :render_error
      rescue_from ActiveRecord::RecordNotFound,        with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid,         with: :render_record_invalid
      rescue_from ActionController::RoutingError,      with: :render_not_found
      rescue_from ActionController::ParameterMissing,  with: :render_parameter_missing
      rescue_from AbstractController::ActionNotFound,  with: :render_not_found

      private

      def render_error
        render json: { error: 'An error ocurred' }, status: 500 unless performed?
      end

      def render_not_found
        render json: { error: "Couldn't find the record" }, status: :not_found
      end

      def render_record_invalid(exception)
        render json: { errors: exception.record.errors.as_json }, status: :bad_request
      end

      def render_parameter_missing
        render json: { error: 'A required parameter is missing' }, status: :unprocessable_entity
      end

      def current_partner
        api_key = request.headers['X-Api-Key']
        @current_partner ||= Partners::GetPartnerByApiKey.call(api_key: api_key)
      end

      def authenticate_partner!
        unless current_partner
          head :unauthorized
        end
      end

      def check_json_request
        if request.method == 'POST' || request.method == 'PUT'
          head :not_acceptable unless request.content_type =~ /json/
        end
      end
    end
  end
end
