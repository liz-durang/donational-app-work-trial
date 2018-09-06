module Api
  module V1
    module PortfolioContributions
      class ContributionsController < Api::V1::ApiController
        def create
          pipeline = Flow.new
          pipeline.chain { create_selected_portfolio! }
          pipeline.chain { schedule_first_contribution! }

          outcome = pipeline.run

          unless outcome.success?
            render json: { errors: outcome.errors.message_list }, status: 422
          end
        end

        private

        def contributions_params
          params.require(:contribution).permit(:donor_id, :amount)
        end

        def portfolio
          @portfolio ||= Portfolios::GetPortfolioById.call(id: params[:portfolio_id])
        end

        def donor
          @donor ||= Donors::GetDonorById.call(id: contributions_params[:donor_id])
        end

        def active_portfolio
          @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: donor)
        end

        def amount_cents
          contributions_params[:amount].to_i * 100
        end

        def create_selected_portfolio!
          Portfolios::SelectPortfolio.run(
            donor: donor,
            portfolio: portfolio
          )
        end

        def schedule_first_contribution!
          command = Contributions::ScheduleContribution.run(
            donor: donor,
            portfolio: active_portfolio,
            amount_cents: amount_cents,
            tips_cents: 0,
            scheduled_at: Time.zone.now
          )

          @contribution = command.result if command.success?
          command
        end
      end
    end
  end
end
