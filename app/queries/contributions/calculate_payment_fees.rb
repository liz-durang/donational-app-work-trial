module Contributions
  class CalculatePaymentFees < ApplicationQuery
    attr_reader :contribution

    DONATIONAL_PLATFORM_FEE_RATE = 0.00
    STRIPE_FIXED_FEE = 30
    STRIPE_FEE_RATE = 0.029
    PANDA_PAY_RATE = 0.01

    def call(contribution:)
      @contribution = contribution

      OpenStruct.new(
        amount_cents: contribution.amount_cents,
        tips_cents: contribution.tips_cents,
        total_charge_amount_cents: total_charge_amount_cents,
        platform_fee_cents: platform_fee_cents,
        payment_processor_fees_cents: payment_processor_fees_cents,
        donor_advised_fund_fees_cents: donor_advised_fund_fees_cents,
        amount_donated_after_fees_cents: contribution.amount_cents - total_fees_cents
      )
    end

    private

    def platform_fee_cents
      partner = Partners::GetPartnerForDonor.call(donor: contribution.donor)

      fee_rate = partner ? partner.platform_fee_percentage : DONATIONAL_PLATFORM_FEE_RATE

      (contribution.amount_cents * fee_rate).ceil
    end

    def total_charge_amount_cents
      contribution.amount_cents + contribution.tips_cents
    end

    def payment_processor_fees_cents
      fixed_fee_cents = STRIPE_FIXED_FEE
      fee_rate = STRIPE_FEE_RATE
      (total_charge_amount_cents * fee_rate).ceil + fixed_fee_cents
    end

    def donor_advised_fund_fees_cents
      fee_rate = PANDA_PAY_RATE
      (contribution.amount_cents * fee_rate).ceil
    end

    def total_fees_cents
      payment_processor_fees_cents + donor_advised_fund_fees_cents + platform_fee_cents
    end
  end
end
