module Subscriptions
  class ValidatePledgeForm < ApplicationCommand
    required do
      model :pledge_form
    end

    def validate
      return if pledge_form.valid?

      pledge_form.errors.full_messages.each do |message|
        add_error(:pledge_form, :validation_error, message)
      end
    end
  end
end
