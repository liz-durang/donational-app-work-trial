module Api
  module V1
    class HooksController < Api::V1::ApiController
      def create
        pipeline = Flow.new
        pipeline.chain { create_webhook! }

        outcome = pipeline.run

        unless outcome.success?
          render json: { errors: outcome.errors.message_list }, status: 422
        end
      end

      def index
          render json: { }, status: 200
      end

      private

      def create_webhook!
        command = Hooks::CreateOrUpdateWebhook.run(
          hook_url: params[:hook_url],
          hook_type: params[:hook_type],
          partner_id: current_partner.id
        )

        @webhook = command.result if command.success?
        command
      end
    end
  end
end
