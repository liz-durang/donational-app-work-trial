module Payments
  class GetPaymentProcessorAccountId < ApplicationQuery
    attr_reader :donor

    DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID = 'acct_1CkEP6CqQ8lwp5WU'

    def call(donor:)
      @donor = donor

      payment_processor_account_id
    end

    private

    def payment_processor_account_id
      partner = Partners::GetPartnerForDonor.call(donor: donor)

      account_id = partner ? partner.payment_processor_account_id : DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID

      account_id
    end
  end
end
