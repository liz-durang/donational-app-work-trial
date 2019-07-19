module Api
  module V1
    class ContributionsController < Api::V1::ApiController
      def create
        command = if contribution_params[:portfolio_id]
          create_contribution_for_a_portfolio
        elsif contribution_params[:organization_ein]
          create_contribution_for_a_single_organization
        end

        if command.nil?
          render json: { errors: 'Either Organization ein or Portfolio id should be present' }, status: 422
        end

        if command.success?
          @contribution = command.result
        else
          render json: { errors: command.errors.message_list }, status: 422
        end
      end

      private

      def create_contribution_for_a_portfolio
        portfolio = Portfolios::GetPortfolioById.call(id: contribution_params[:portfolio_id])
        mark_as_paid = contribution_params[:mark_as_paid] || false

        Contributions::ScheduleContribution.run(
          donor: donor,
          portfolio: portfolio,
          amount_cents: amount_cents,
          tips_cents: 0,
          scheduled_at: Time.zone.now,
          external_reference_id: contribution_params[:external_reference_id],
          mark_as_paid: mark_as_paid,
          receipt: contribution_params[:receipt]
        )
      end

      def create_contribution_for_a_single_organization
        mark_as_paid = contribution_params[:mark_as_paid] || false
        find_organization = Organizations::FindOrCreateDonorSuggestedCharity.run(
          ein: contribution_params[:organization_ein],
          suggested_by: donor
        )

        return find_organization unless find_organization.success?

        Contributions::ScheduleContributionForSingleOrganization.run(
          donor: donor,
          organization: find_organization.result,
          amount_cents: amount_cents,
          tips_cents: 0,
          scheduled_at: Time.zone.now,
          external_reference_id: contribution_params[:external_reference_id],
          mark_as_paid: mark_as_paid,
          receipt: contribution_params[:receipt]
        )
      end

      def contribution_params
        receipt_keys = params.require(:contribution).fetch(:receipt, {})&.keys
        params
          .require(:contribution)
          .permit(:donor_id, :amount_cents, :currency, :organization_ein, :portfolio_id, :external_reference_id, :mark_as_paid, receipt: receipt_keys)
          .to_h
      end

      def donor
        @donor ||= Donors::GetDonorById.call(id: contribution_params[:donor_id])
      end

      def amount_cents
        contribution_params[:amount_cents].to_i
      end
    end
  end
end
