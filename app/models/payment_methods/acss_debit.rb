module PaymentMethods
  class AcssDebit < PaymentMethod
    def self.payment_processor_payment_method_type_code
      :acss_debit
    end

    def self.human_readable_name
      'Direct Debit'
    end
  end
end
