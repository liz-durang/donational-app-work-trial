module Contributions
  class GetTargetContributionAmountCents < ApplicationQuery
    def call(donor:, frequency:)
      return nil unless donor.annual_income_cents
      return nil unless donor.donation_rate

      target_annual_amount_cents = donor.donation_rate * donor.annual_income_cents

      case frequency
      when 'annually'
        target_annual_amount_cents
      when 'quarterly'
        target_annual_amount_cents / 4.0
      when 'monthly'
        target_annual_amount_cents / 12.0
      when 'once'
        target_annual_amount_cents / 12.0
      else
        nil
      end
    end
  end
end
