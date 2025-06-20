# frozen_string_literal: true

require Rails.root.join('lib', 'mutations', 'symbol_filter')

module Contributions
  class CreateOrReplaceSubscription < ApplicationCommand
    required do
      model :donor
      model :portfolio
      model :partner
      symbol :frequency, default: :monthly, in: Subscription.frequency.values
      integer :amount_cents, min: 0
      integer :tips_cents, min: 0, default: 0
    end

    optional do
      time :start_at
      integer :partner_contribution_percentage, min: 0, default: 0
      boolean :migration, default: false
      integer :trial_amount_cents, min: 0, default: 0
    end

    def execute
      Subscription.transaction do
        # ensure we don't force a new donation when donor updates their plan settings
        new_contribution = existing_subscriptions.empty?

        most_recent_last_scheduled_at = previous_plans_most_recent_scheduled_at
        trial_most_recent_last_scheduled_at = previous_trials_most_recent_scheduled_at
        deactivate_existing_subscriptions!

        subscription = Subscription.create!(
          donor: donor,
          portfolio: portfolio,
          partner: partner,
          frequency: frequency,
          start_at: start_at || Time.zone.now,
          amount_cents: amount_cents,
          tips_cents: tips_cents,
          last_scheduled_at: frequency == :once ? nil : most_recent_last_scheduled_at,
          partner_contribution_percentage: partner_contribution_percentage,
          amount_currency: partner.currency,
          trial_amount_cents: trial_amount_cents,
          trial_start_at: trial_amount_cents > 0 ? Time.zone.now : nil,
          trial_last_scheduled_at: trial_most_recent_last_scheduled_at
        )

        Portfolios::SelectPortfolio.run(donor: donor, portfolio: portfolio)

        unless migration
          send_confirmation_email!(subscription)
          TriggerSubscriptionWebhook.perform_async(new_contribution ? 'create' : 'update', partner.id, subscription.id)
        end
      end

      nil
    end

    private

    def existing_subscriptions
      @existing_subscriptions ||=
        Contributions::GetActiveSubscriptions.call(donor: donor)
    end

    def previous_plans_most_recent_scheduled_at
      existing_subscriptions.maximum(:last_scheduled_at)
    end

    def previous_trials_most_recent_scheduled_at
      existing_subscriptions.maximum(:trial_last_scheduled_at)
    end

    def deactivate_existing_subscriptions!
      existing_subscriptions.update_all(deactivated_at: Time.zone.now, trial_deactivated_at: Time.zone.now)
    end

    def send_confirmation_email!(subscription)
      payment_method = Payments::GetActivePaymentMethod.call(donor: subscription.donor)
      partner = Partners::GetPartnerForDonor.call(donor: subscription.donor)

      return if Rails.env.staging?

      ConfirmationsMailer.send_confirmation(
        subscription: subscription,
        payment_method: payment_method,
        partner: partner,
        cancelation: false
      ).deliver_now
    end
  end
end
