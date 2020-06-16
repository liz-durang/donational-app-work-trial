module Partners
  class DonorsController < ApplicationController
    before_action :ensure_donor_has_permission!

    def index
      @view_model = OpenStruct.new(partner: partner, donors: donors)
    end

    def new
      @view_model = OpenStruct.new(
        partner: partner,
        donor: Donor.new
      )
    end

    def edit
      @view_model = OpenStruct.new(
        partner: partner,
        donor_responses: donor_responses,
        donor: donor,
        recurring_contribution: active_recurring_contribution,
        first_contribution: Contributions::GetFirstContribution.call(donor: donor),
        partner_affiliation: partner_affiliation,
        selectable_portfolios: selectable_portfolios,
        payment_method: active_payment_method || new_payment_method,
        contributions: contributions,
        donor_path: partner_donor_path
      )
    end

    def create
      if required_fields_left_blank.blank?
        pipeline = Flow.new
        new_donor = Donors::CreateAnonymousDonor.run!
        pipeline.chain { Partners::AffiliateDonorWithPartner.run(donor: new_donor, partner: partner) }
        pipeline.chain {
        Donors::UpdateDonor.run(
          donor: new_donor,
          email: params[:email].presence,
          first_name: params[:first_name].presence,
          last_name: params[:last_name].presence
        ) }
        pipeline.chain {
        Partners::UpdateCustomDonorInformation.run(
          donor: new_donor,
          partner: partner,
          responses: custom_responses
        ) }

        outcome = pipeline.run

        if outcome.success?
          flash[:success] = "Donor Created Successfully"
        else
          flash[:error] = outcome.errors.message_list.join("\n")
        end
        redirect_to partner_donors_path(partner)  
      else
        flash[:error] = "Please fill in the required field(s):\n" + required_fields_left_blank.join(", ")
        redirect_to new_partner_donor_path(partner)
      end
    end

    def update
      if required_fields_left_blank.blank?
        pipeline = Flow.new
        pipeline.chain { update_donor! }
        pipeline.chain { update_custom_responses! }

        outcome = pipeline.run

        if outcome.success?
          flash[:success] = "Donor Updated Successfully"
        else
          flash[:error] = outcome.errors.message_list.join("\n")
        end
      else
        flash[:error] = "Please fill in the required field(s):\n" + required_fields_left_blank.join("\n")
      end
      redirect_to edit_partner_donor_path(partner, donor)
    end

    private

    def update_donor!
      command = Donors::UpdateDonor.run(
        donor: donor,
        email: params[:email].presence,
        first_name: params[:first_name].presence,
        last_name: params[:last_name].presence
      )
    end

    def ensure_donor_has_permission!
      unless current_donor.partners.exists?(id: partner.id)
        flash[:error] = "Sorry, you don't have permission to create a donor for this partner."
        redirect_to new_partner_donor_path(partner)
      end
    end

    def update_custom_responses!
      Partners::UpdateCustomDonorInformation.run(
        donor: donor,
        partner: partner,
        responses: custom_responses
      )
    end

    def required_fields_left_blank
      validated = []
      validated << 'Email' if !params[:email].present?
      validated << 'First Name' if !params[:first_name].present?
      validated << 'Last Name' if !params[:last_name].present?
      @partner.donor_questions.each do |question|
        if question.required
          validated << question.title if !params[question.name].present?
        end
      end
      validated
    end

    def custom_responses
      permitted_question_keys = partner.donor_questions.map(&:name)
      params
        .permit(permitted_question_keys)
        .to_h
    end

    def new_payment_method
      donor.payment_methods.new
    end

    def active_payment_method
      @active_payment_method ||= Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def active_recurring_contribution
      @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: donor)
    end

    def partner_affiliation
      @partner_affiliation ||= Partners::GetPartnerAffiliationByDonor.call(donor: donor)
    end

    def active_portfolio
      Portfolios::GetActivePortfolio.call(donor: donor)
    end

    def managed_portfolio?
      Portfolios::GetPortfolioManager.call(portfolio: active_portfolio).present?
    end

    def selectable_portfolios
      portfolios = []
      portfolios << [active_portfolio.id, 'My personalized portfolio'] if active_portfolio && !managed_portfolio?
      portfolios += Partners::GetManagedPortfoliosForPartner.call(partner: partner).pluck(:portfolio_id, :name) if partner
      portfolios
    end

    def partner
      @partner = Partners::GetPartnerById.call(id: params[:partner_id])
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:id])
    end

    def donors
      @donors = if search
        Partners::ListDonorsFromSearch.call(search: search, partner: partner, page: params[:page])
      else
        Donor.joins(:partner_affiliations).where(partner_affiliations: { partner_id: partner.id }).order('updated_at': :desc).page(params[:page]).per(10)
      end
    end

    def contributions
      @contributions = Contributions::GetContributions.call(
        donor: donor
      )
    end

    def search
      @search = params[:term].present? ? params[:term] : nil
    end

    def donor_responses
      partner_affiliation = Partners::GetPartnerAffiliationByDonorAndPartner.call(
        donor: donor,
        partner: partner
      )
      return [] unless partner_affiliation.custom_donor_info

      partner_affiliation.donor_responses.map{ |r| [r.question.name,r.value] }.to_h
    end
  end
end
