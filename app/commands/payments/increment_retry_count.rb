module Payments
  class IncrementRetryCount < ApplicationCommand
    required do
      model :payment_method
    end

    def execute
      payment_method.update!(retry_count: payment_method.retry_count + 1)

      nil
    end
  end
end
