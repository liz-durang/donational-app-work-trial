module Partners
  class RefundsController < ApplicationController
    include Secured

    def create

      if Donations::AlreadyBeenGranted.call(contribution: contribution)
        flash[:error] = "This contribution could not be refunded, as it has already been assigned to one or more grants to organizations"
      else
        outcome = Contributions::RefundContribution.run(contribution: contribution)

        if outcome.success?
          flash[:success] = "Contribution Refunded Successfully"
        else
          flash[:error] = outcome.errors.message_list.join("\n")
        end
      end
      redirect_to edit_partner_donor_path(partner, donor)
    end

    private

    def contribution
      @contribution = Contributions::GetContributionById.call(id: params[:contribution_id])
    end

    def partner
      @partner = contribution.partner_id
    end

    def donor
      @donor = contribution.donor
    end
  end
end
