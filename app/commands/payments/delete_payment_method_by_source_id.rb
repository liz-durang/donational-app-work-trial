module Payments
  class DeletePaymentMethodBySourceId < ApplicationCommand
    required do
      string :source_id
    end

    def execute
      payment_method = PaymentMethod.where(
        payment_processor_source_id: source_id,
        type: 'PaymentMethods::AcssDebit'
      ).first

      unless payment_method.present?
        add_error(:payment_method, :not_found, "Payment method not found: #{source_id}")
        return
      end

      payment_method.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      add_error(:payment_method, :not_destroyed, "Payment method could not be destroyed")
      nil
    end
  end
end
