# frozen_string_literal: true

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
        active: active_subscription.present?,
        subscription: active_subscription || new_subscription,
        first_contribution: Contributions::GetFirstContribution.call(donor: donor),
        partner_affiliation: partner_affiliation,
        selectable_portfolios: selectable_portfolios,
        payment_method: active_payment_method || new_payment_method,
        contributions: contributions,
        donor_path: partner_donor_path,
        uk_gift_aid_accepted: donor.uk_gift_aid_accepted,
        title: donor.title,
        house_name_or_number: donor.house_name_or_number,
        postcode: donor.postcode,
      )
    end

    def create
      if required_fields_left_blank.blank?
        pipeline = Flow.new
        new_donor = Donors::CreateAnonymousDonorAffiliatedWithPartner.run!(partner: partner)
        pipeline.chain do
          Donors::UpdateDonor.run(
            donor: new_donor,
            email: params[:email].presence,
            first_name: params[:first_name].presence,
            last_name: params[:last_name].presence,
            title: params[:title].presence,
            house_name_or_number: params[:house_name_or_number].presence,
            postcode: params[:postcode].presence,
            uk_gift_aid_accepted: params[:uk_gift_aid_accepted].presence
          )
        end
        pipeline.chain do
          Partners::UpdateCustomDonorInformation.run(
            donor: new_donor,
            partner: partner,
            responses: custom_responses
          )
        end

        outcome = pipeline.run

        if outcome.success?
          flash[:success] = 'Donor Created Successfully'
        else
          flash[:error] = outcome.errors.message_list.join("\n")
        end
        redirect_to partner_donors_path(partner)
      else
        flash[:error] = "Please fill in the required field(s):\n" + required_fields_left_blank.join(', ')
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
          flash[:success] = 'Donor Updated Successfully'
        else
          flash[:error] = outcome.errors.message_list.join("\n")
        end
      else
        flash[:error] = "Please fill in the required field(s):\n" + required_fields_left_blank.join("\n")
      end
      redirect_to edit_partner_donor_path(partner, donor)
    end

    def destroy
      outcome = Donors::DeactivateDonor.run(donor: donor)

      if outcome.success?
        flash[:success] = 'Donor deleted successfully'
        redirect_to partner_donors_path(partner)
      else
        flash[:error] = outcome.errors.message_list.join("\n")
        redirect_to edit_partner_donor_path(partner, donor)
      end
    end

    private

    def update_donor!
      command = Donors::UpdateDonor.run(
        donor: donor,
        email: params[:email].presence,
        first_name: params[:first_name].presence,
        last_name: params[:last_name].presence,
        title: params[:title].presence,
        house_name_or_number: params[:house_name_or_number].presence,
        postcode: params[:postcode].presence,
        uk_gift_aid_accepted: params[:uk_gift_aid_accepted].presence
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
      validated << 'Email' if params[:email].blank?
      validated << 'First Name' if params[:first_name].blank?
      validated << 'Last Name' if params[:last_name].blank?
      @partner.donor_questions.each do |question|
        if question.required
          validated << question.title if params[question.name].blank?
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

    def new_subscription
      donor.subscriptions.new
    end

    def active_payment_method
      @active_payment_method ||= Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def active_subscription
      @active_subscription ||= Contributions::GetActiveSubscription.call(donor: donor)
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
      if active_portfolio && !managed_portfolio?
        portfolios << [active_portfolio.id, 'My personalized portfolio']
      end
      if partner
        portfolios += Partners::GetManagedPortfoliosForPartner.call(partner: partner).pluck(:portfolio_id, :name)
      end
      portfolios
    end

    def partner
      @partner = Partners::GetPartnerById.call(id: params[:partner_id])
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:id])
    end

    def donors
      @donors = Partners::ListDonors.call(search: search, partner: partner, page: params[:page])
    end

    def contributions
      @contributions = Contributions::GetContributions.call(
        donor: donor
      )
    end

    def search
      @search = params[:term].presence
    end

    def donor_responses
      partner_affiliation = Partners::GetPartnerAffiliationByDonorAndPartner.call(
        donor: donor,
        partner: partner
      )
      return [] unless partner_affiliation.custom_donor_info

      partner_affiliation.donor_responses.map { |r| [r.question.name, r.value] }.to_h
    end
  end
end
