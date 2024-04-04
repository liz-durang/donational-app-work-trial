module Constants
  class GetLocalizedPaymentMethods < ApplicationQuery
    def call
      # Order: Always list card last / bank first in each array.
      { GBP: [PaymentMethods::BacsDebit, PaymentMethods::Card],
        CAD: [PaymentMethods::AcssDebit, PaymentMethods::Card],
        AUD: [PaymentMethods::Card],
        USD: [PaymentMethods::BankAccount, PaymentMethods::Card] }.with_indifferent_access.freeze
    end
  end
end
