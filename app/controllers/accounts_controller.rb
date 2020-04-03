class AccountsController < ApplicationController
  include Secured

  def update
    pipeline = Flow.new
    pipeline.chain { update_donor! } if params[:donor].present?
    pipeline.chain { update_custom_responses! } if params[:donor_responses].present?

    outcome = pipeline.run

    if outcome.success?
      flash[:success] = "Thanks, we've updated your information"
    else
      flash[:error] = outcome.errors.message_list.join("\n")
    end

    redirect_to edit_accounts_path
  end

  def edit
    @view_model = OpenStruct.new(
      donor: current_donor,
      accounts_path: accounts_path,
      payment_method: active_payment_method || new_payment_method,
      recurring_contribution: active_recurring_contribution,
      first_contribution: Contributions::GetFirstContribution.call(donor: current_donor),
      target_amount_cents: target_amount_cents,
      partner_affiliation: partner_affiliation,
      selectable_portfolios: selectable_portfolios,
      donor_responses: donor_responses,
      currency: current_currency,
      uk_partner?: uk_partner?
    )
  end

  private

  def update_donor!
    Donors::UpdateDonor.run(
      donor: current_donor,
      title: params[:donor][:title],
      first_name: params[:donor][:first_name],
      last_name: params[:donor][:last_name],
      email: params[:donor][:email],
      house_name_or_number: params[:donor][:house_name_or_number],
      postcode: params[:donor][:postcode],
      uk_gift_aid_accepted: params[:donor][:uk_gift_aid_accepted]
    )
  end

  def update_custom_responses!
    Partners::UpdateCustomDonorInformation.run(
      donor: current_donor,
      partner: partner,
      responses: custom_responses
    )
  end

  def custom_responses
    permitted_question_keys = partner.donor_questions.map(&:name)
    params
      .permit(donor_responses: permitted_question_keys)[:donor_responses]
      .to_h
  end

  def donor_responses
    return [] unless partner_affiliation

    partner_affiliation.donor_responses
  end

  def new_payment_method
    current_donor.payment_methods.new
  end

  def active_payment_method
    @active_payment_method ||= Payments::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_recurring_contribution
    @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: current_donor)
  end

  def target_amount_cents
    Contributions::GetTargetContributionAmountCents.call(
      donor: current_donor,
      frequency: active_recurring_contribution&.frequency || current_donor.contribution_frequency
    )
  end

  def partner_affiliation
    @partner_affiliation ||= Partners::GetPartnerAffiliationByDonor.call(donor: current_donor)
  end

  def active_portfolio
    Portfolios::GetActivePortfolio.call(donor: current_donor)
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
    @partner ||= Partners::GetPartnerForDonor.call(donor: current_donor)
  end

  def uk_partner?
    partner.currency == 'GBP'
  end
end
