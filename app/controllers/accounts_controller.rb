class AccountsController < ApplicationController
  include Secured

  def update
    command = Donors::UpdateDonor.run(
      donor: current_donor,
      first_name: params[:donor][:first_name],
      last_name: params[:donor][:last_name],
      email: params[:donor][:email]
    )

    if command.success?
      flash[:success] = "Thanks, we've updated your account"
      redirect_to edit_accounts_path
    else
      flash[:error] = command.errors.message_list.join('. ')
      redirect_to edit_accounts_path
    end
  end

  def edit
    @view_model = OpenStruct.new(
      donor: current_donor,
      accounts_path: accounts_path,
      payment_method: active_payment_method || new_payment_method,
      recurring_contribution: active_recurring_contribution,
      target_amount_cents: target_amount_cents
    )
  end

  private

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
end
