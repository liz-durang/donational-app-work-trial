# frozen_string_literal: true

module Contributions
  class ProcessContributionAcssOrBacsPaymentSucceeded < ApplicationCommand
    required do
      model :charge, class: Stripe::Charge
      string :account_id
    end

    def validate
      ensure_contribution_id_present!
    end

    def execute
      chain { update_contribution_fees }
      chain { process_contribution_payment_succeedeed }

      nil
    end

    private

    def ensure_contribution_id_present!
      contribution_id = charge[:metadata][:contribution_id]
      return if contribution_id.present?

      add_error(:contribution, :contribution_id_missing, 'Could not find contribution id in metadata')
    end

    def contribution
      @contribution ||= begin
        contribution_id = charge[:metadata][:contribution_id]
        Contribution.find_by(id: contribution_id)
      end
    end

    def update_contribution_fees
      # Update payment processor fee in contribution
      fee = balance_transaction[:fee_details].detect { |f| f[:type] == 'stripe_fee' }
      payment_processor_fees_cents = fee[:amount]
      contribution.update(payment_processor_fees_cents:)

      # We can now calculate the total fees
      payment_fees = Contributions::CalculatePaymentFees.call(contribution:)
      contribution.update(
        donor_advised_fund_fees_cents: payment_fees.donor_advised_fund_fees_cents,
        amount_donated_after_fees_cents: payment_fees.amount_donated_after_fees_cents
      )

      Mutations::Outcome.new(true, nil, [], nil)
    end

    def balance_transaction
      @balance_transaction ||= begin
        Rails.logger.info("ACSS or BACS debit charge. Will fetch balance transaction #{charge.balance_transaction} for account #{account_id}")
        Stripe::BalanceTransaction.retrieve(charge.balance_transaction, { stripe_account: account_id })
      end
    end

    def process_contribution_payment_succeedeed
      Contributions::ProcessContributionPaymentSucceeded.run(contribution:, receipt: charge.to_json)
    end
  end
end
