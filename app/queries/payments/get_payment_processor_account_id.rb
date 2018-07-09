module Payments
  class GetPaymentProcessorAccountId < ApplicationQuery

    def call(donor:)
      partner = Partners::GetPartnerForDonor.call(donor: donor)

      account_id = partner ? partner.payment_processor_account_id : ENV.fetch('DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID')
    end
  end
end
