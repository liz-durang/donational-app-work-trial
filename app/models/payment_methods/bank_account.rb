# US Bank Account
module PaymentMethods
  # This payment method pertains only to US bank accounts; that is, ACH Direct Debit.
  # We can't change the class name to be more specific without migrating the existing PaymentMethod column.
  class BankAccount < PaymentMethod
    def self.payment_processor_payment_method_type_code
      :us_bank_account
    end

    def self.human_readable_name
      'Direct Debit'
    end
  end
end
