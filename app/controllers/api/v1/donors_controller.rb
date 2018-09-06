module Api
  module V1
    class DonorsController < Api::V1::ApiController
      def create
        pipeline = Flow.new
        pipeline.chain { create_donor! }
        pipeline.chain { associate_donor_with_partner!(donor: @donor) }

        outcome = pipeline.run

        unless outcome.success?
          render json: { errors: outcome.errors.message_list }, status: 422
        end
      end

      private

      def donor_params
        params.require(:donor).permit(:first_name, :last_name, :email)
      end

      def create_donor!
        command = Donors::CreateDonor.run(
          first_name: donor_params[:first_name],
          last_name: donor_params[:last_name],
          email: donor_params[:email]
        )

        @donor = command.result if command.success?
        command
      end

      def associate_donor_with_partner!(donor:)
        Partners::AffiliateDonorWithPartner.run(donor: donor, partner: current_partner)
      end
    end
  end
end
