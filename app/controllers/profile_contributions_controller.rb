class ProfileContributionsController < ApplicationController
  skip_forgery_protection only: [:create]

  def create
    pipeline = Flow.new
    pipeline.chain { create_donor! } unless current_donor
    pipeline.chain { update_donor_payment_method! } if payment_method_id.present? || payment_token.present?
    pipeline.chain { update_subscription! }

    outcome = pipeline.run

    if outcome.success?
      redirect_to portfolio_path(show_modal: true)
    else
      redirect_to profiles_path(referrer_donor.username), alert: outcome.errors.message_list.join("\n")
    end
  end

  private

  def create_donor!
    outcome = Donors::CreateDonorAffiliatedWithPartner.run(
      first_name: params[:profile_contribution][:first_name],
      last_name: params[:profile_contribution][:last_name],
      email: params[:profile_contribution][:email],
      referred_by_donor_id: params[:profile_contribution][:referrer_donor_id],
      partner: partner
    )

    log_in!(outcome.result) if outcome.success?

    outcome
  end

  def update_donor_payment_method!
    Payments::UpdatePaymentMethod.run(
      donor: current_donor,
      payment_token: payment_token,
      payment_method_id: payment_method_id
    )
  end

  def update_subscription!
    Contributions::CreateOrReplaceSubscription.run(
      donor: current_donor,
      portfolio: portfolio,
      partner: partner,
      amount_cents: params[:profile_contribution][:amount_dollars].to_i * 100,
      frequency: params[:profile_contribution][:frequency],
      start_at: start_at,
      tips_cents: 0
    )
  end

  def referrer_donor
    @donor ||= Donors::GetDonorById.call(id: params[:profile_contribution][:referrer_donor_id])
  end

  def portfolio
    @portfolio ||= Portfolios::GetPortfolioById.call(id: params[:profile_contribution][:portfolio_id])
  end

  def partner
    @partner ||= Partners::GetPartnerForDonor.call(donor: referrer_donor)
  end

  def payment_method_id
    params[:profile_contribution][:payment_method_id]
  end

  def payment_token
    params[:profile_contribution][:payment_token]
  end

  def start_at
    start_at_month = params.dig(:profile_contribution, :start_at_month)
    start_at_year = params.dig(:profile_contribution, :start_at_year)

    return nil if start_at_month.blank? || start_at_year.blank?

    Time.zone.local(start_at_year, start_at_month, 15, 12, 0)
  end
end
