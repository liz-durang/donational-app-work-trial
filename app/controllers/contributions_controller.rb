class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)

    redirect_to new_contributions_path if @contributions.empty?
  end

  def new
    redirect_to edit_accounts_path if active_recurring_contribution

    @view_model = OpenStruct.new(
      target_amount_cents: target_amount_cents,
      recurring_contribution: active_recurring_contribution || new_recurring_donation,
      active_payment_method: payment_method.present?,
      portfolio_organization_count: active_portfolio.active_allocations.count
    )
  end

  def create
    pipeline = Flow.new
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! }
    pipeline.chain { schedule_first_contribution_immediately! }

    new_unprocessed_contributions = Contributions::GetUnprocessedContributions.call(donor: current_donor)
    new_unprocessed_contributions.each do |c|
      pipeline.chain { Contributions::ProcessContribution.run(contribution: c) }
    end

    outcome = pipeline.run

    if outcome.success?
      track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })
      flash[:success] = "We've updated your donation plan"
      redirect_to edit_accounts_path
    else
      redirect_to new_contributions_path, alert: outcome.errors.message_list.join('\n')
    end
  end

  def destroy
    Contributions::DeactivateRecurringContribution.run(recurring_contribution: active_recurring_contribution)

    flash[:success] = "We've cancelled your donation plan"
    redirect_to edit_accounts_path
  end

  private

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run!(
      donor: current_donor,
      payment_token: payment_token,
      name_on_card: name_on_card,
      last4: last4
    )
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      frequency: frequency,
      amount_cents: amount_cents,
      tips_cents: tips_cents,
      start_at: start_at.presence
    )
  end

  def schedule_first_contribution_immediately!
    Contributions::ScheduleContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      amount_cents: amount_cents,
      tips_cents: tips_cents,
      scheduled_at: Time.zone.now
    )
  end

  def payment_method
    @payment_method = Payments::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_recurring_contribution
    @active_contribution ||= Contributions::GetActiveRecurringContribution.call(donor: current_donor)
  end

  def new_recurring_donation
    RecurringContribution.new(
      donor: current_donor,
      amount_cents: target_amount_cents,
      portfolio: active_portfolio,
      frequency: current_donor.contribution_frequency
    )
  end

  def target_amount_cents
    Contributions::GetTargetContributionAmountCents.call(
      donor: current_donor,
      frequency: active_recurring_contribution.try(:frequency) || current_donor.contribution_frequency
    )
  end

  def amount_cents
    amount_dollars * 100
  end

  def tips_cents
    params[:recurring_contribution][:tips_cents].to_i
  end

  def amount_dollars
    params[:recurring_contribution][:amount_dollars].to_i
  end

  def payment_token
    params[:recurring_contribution][:payment_token]
  end

  def frequency
    params[:recurring_contribution][:frequency]
  end

  def start_at
    params[:recurring_contribution][:start_at]
  end

  def name_on_card
    params[:recurring_contribution][:name_on_card]
  end

  def last4
    params[:recurring_contribution][:last4]
  end
end
