module Contributions
  class GetTargetContributionAmountCents < ApplicationQuery
    def call(donor:, frequency:)
      return nil unless donor.target_annual_contribution_amount_cents

      case frequency
      when 'annually'
        donor.target_annual_contribution_amount_cents
      when 'quarterly'
        donor.target_annual_contribution_amount_cents / 4.0
      when 'monthly'
        donor.target_annual_contribution_amount_cents / 12.0
      when 'once'
        donor.target_annual_contribution_amount_cents / 12.0
      else
        nil
      end
    end
  end
end
