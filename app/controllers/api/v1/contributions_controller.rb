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
          render_errors({ contribution: 'Either Organization ein or Portfolio id should be present' }, :bad_request)
        end

        if command.success?
          @contribution = command.result
        else
          render_errors(command.errors.message, :bad_request)
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
          receipt: contribution_params[:receipt],
          partner: current_partner,
          partner_contribution_percentage: 0
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
          receipt: contribution_params[:receipt],
          partner: current_partner,
          partner_contribution_percentage: 0
        )
      end

      def contribution_params
        receipt_keys = params.require(:contribution).fetch(:receipt, {})&.keys
        params
          .require(:contribution)
          .permit(:donor_id, :donor_first_name, :donor_last_name, :donor_entity_name, :donor_email, :amount_cents, :currency,
                  :organization_ein, :portfolio_id, :external_reference_id, :mark_as_paid, receipt: receipt_keys)
          .to_h
      end

      def donor
        return donor_by_id if donor_id.present?

        return donor_by_email if donor_email.present? && donor_by_email.present?

        outcome = Donors::CreateDonorAffiliatedWithPartner.run(
          email: donor_email,
          entity_name: donor_entity_name,
          first_name: donor_first_name,
          last_name: donor_last_name,
          partner: current_partner
        )

        if outcome.success?
          @donor ||= outcome.result
        else
          render_errors(outcome.errors.message, :bad_request)
        end
      end

      def donor_by_id
        @donor ||= Donors::GetDonorById.call(id: donor_id)
      end

      def donor_by_email
        @donor ||= Donors::GetDonorByEmail.call(email: donor_email)
      end

      def donor_id
        contribution_params[:donor_id]
      end

      def donor_email
        contribution_params[:donor_email]
      end

      def donor_first_name
        contribution_params[:donor_first_name]
      end

      def donor_last_name
        contribution_params[:donor_last_name]
      end

      def donor_entity_name
        contribution_params[:donor_entity_name]
      end

      def amount_cents
        contribution_params[:amount_cents].to_i
      end
    end
  end
end
