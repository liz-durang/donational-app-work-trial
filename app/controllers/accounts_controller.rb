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
      donor_responses: donor_responses
    )
  end

  private

  def update_donor!
    Donors::UpdateDonor.run(
      donor: current_donor,
      first_name: params[:donor][:first_name],
      last_name: params[:donor][:last_name],
      email: params[:donor][:email]
    )
  end

  def update_custom_responses!
    responses = partner.donor_questions.map do |q|
      PartnerAffiliation::DonorResponse.new(question: q, value: params[:donor_responses][q.name])
    end

    Partners::UpdateCustomDonorInformation.run(
      donor: current_donor,
      partner: partner,
      responses: responses
    )
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

  def partner
    @partner ||= Partners::GetPartnerForDonor.call(donor: current_donor)
  end
end
