module PaymentMethods
  class BacsDebit < PaymentMethod
    def self.payment_processor_payment_method_type_code
      :bacs_debit
    end

    def self.human_readable_name
      'Direct Debit'
    end
  end
end
