module PaymentMethods
  class GetActivePaymentMethod < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(donor:)
      # @relation
      #   .where(donor: donor)
      #   .where.not(payment_token: nil)
      #   .order(created_at: :desc)
      #   .first
      return nil if donor.payment_processor_customer_id.blank?

      OpenStruct.new(
        customer_id: donor.payment_processor_customer_id,
        created_at: donor.updated_at
      )
    end
  end
end
