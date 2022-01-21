module Payments
  class GetPaymentMethodBySourceId < ApplicationQuery
    def initialize(relation = PaymentMethod.all)
      @relation = relation
    end

    def call(source_id:)
      @relation
        .where(payment_processor_source_id: source_id)
        .first
    end
  end
end
