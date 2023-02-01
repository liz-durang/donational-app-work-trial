module Api
  module V1
    class HooksController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        render json: {}, status: :ok
      end

      def create
        pipeline = Flow.new
        pipeline.chain { create_webhook! }

        outcome = pipeline.run

        return if outcome.success?

        render json: { errors: outcome.errors.message_list }, status: :unprocessable_entity
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
