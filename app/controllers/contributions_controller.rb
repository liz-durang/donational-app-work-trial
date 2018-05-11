class ContributionsController < ApplicationController
  include Secured
  include ClientSideAnalytics

  def index
    redirect_to new_contribution_path and return unless active_payment_method?

    @contributions = Contributions::GetProcessedContributions.call(donor: current_donor)
  end

  def new
    active_portfolio
    active_recurring_contribution
    payment_method
  end

  def create
    pipeline = Flow.new
    pipeline.chain { update_donor_payment_method! } if payment_token.present?
    pipeline.chain { update_recurring_contribution! } if frequency.in?(RecurringContribution.frequency.values)
    pipeline.chain { schedule_first_contribution_immediately! }

    new_unprocessed_contributions = Contributions::GetUnprocessedContributions.call(donor: current_donor)
    new_unprocessed_contributions.each do |c|
      pipeline.chain { Contributions::ProcessContribution.run(contribution: c) }
    end

    outcome = pipeline.run

    if outcome.success?
      track_analytics_event_via_browser('Goal: Donation', { revenue: amount_dollars })
      redirect_to contributions_path
    else
      redirect_to new_contribution_path, alert: outcome.errors.message_list.join('\n')
    end
  end

  private

  def update_donor_payment_method!
    Donors::UpdatePaymentMethod.run(donor: current_donor, payment_token: payment_token)
  end

  def update_recurring_contribution!
    Contributions::CreateOrReplaceRecurringContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      frequency: frequency,
      amount_cents: amount_cents,
      platform_fee_cents: platform_fee_cents
    )
  end

  def schedule_first_contribution_immediately!
    Contributions::ScheduleContribution.run(
      donor: current_donor,
      portfolio: active_portfolio,
      amount_cents: amount_cents,
      platform_fee_cents: platform_fee_cents,
      scheduled_at: Time.zone.now
    )
  end

  def active_payment_method?
    payment_method.present?
  end
  helper_method :active_payment_method?

  def payment_method
    @payment_method = PaymentMethods::GetActivePaymentMethod.call(donor: current_donor)
  end

  def active_portfolio
    @active_portfolio ||= Portfolios::GetActivePortfolio.call(donor: current_donor)
  end

  def active_recurring_contribution
    @active_recurring_contribution ||= begin
      Contributions::GetActiveRecurringContribution.call(donor: current_donor) || new_recurring_donation
    end
  end

  def new_recurring_donation
    RecurringContribution.new(
      donor: current_donor,
      portfolio: active_portfolio,
      frequency: current_donor.contribution_frequency
    )
  end

  def amount_cents
    amount_dollars * 100
  end

  def platform_fee_cents
    params[:recurring_contribution][:platform_fee_cents].to_i
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
end
