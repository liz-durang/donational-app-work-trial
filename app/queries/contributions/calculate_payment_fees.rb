module Contributions
  class CalculatePaymentFees < ApplicationQuery
    attr_reader :contribution

    DONATIONAL_PLATFORM_FEE_RATE = 0.00
    DONOR_ADVISED_FUND_FEE_RATE = 0.01

    def call(contribution:)
      @contribution = contribution

      payment_fees =  OpenStruct.new(
        amount_cents: contribution.amount_cents,
        tips_cents: contribution.tips_cents,
        total_charge_amount_cents: total_charge_amount_cents,
        platform_fee_cents: platform_fee_cents,
      )

      if contribution.processed_at.present?
        payment_fees[:payment_processor_fees_cents] = payment_processor_fees_cents
        payment_fees[:donor_advised_fund_fees_cents] = donor_advised_fund_fees_cents
        payment_fees[:amount_donated_after_fees_cents] = contribution.amount_cents - total_fees_cents
      end

      payment_fees
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
      contribution.payment_processor_fees_cents
    end

    def donor_advised_fund_fees_cents
      fee_rate = DONOR_ADVISED_FUND_FEE_RATE
      (contribution.amount_cents * fee_rate).ceil
    end

    def total_fees_cents
      payment_processor_fees_cents + donor_advised_fund_fees_cents + platform_fee_cents
    end
  end
end
