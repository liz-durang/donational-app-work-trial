module PaymentMethods
  class GetActivePaymentMethod < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(donor:)
      donor
        .payment_methods
        .where(deactivated_at: nil)
        .first
    end
  end
end
