module PaymentMethods
  class Card < PaymentMethod
    def self.payment_processor_payment_method_type_code
      :card
    end

    def self.human_readable_name
      'Card'
    end
  end
end
