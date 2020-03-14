module Payments
  class GetPaymentProcessorAccountId < ApplicationQuery

    def call(donor:)
      Partners::GetPartnerForDonor.call(donor: donor).payment_processor_account_id
    end
  end
end
