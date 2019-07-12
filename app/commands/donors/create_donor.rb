module Donors
  class CreateDonor < ApplicationCommand
    required do
      string :first_name
      string :last_name
      string :email
    end

    def validate
      return unless email_already_used?

      add_error(:donor, :email_already_used, 'The email is already in use')
    end

    def execute
      Donor.create!(
        first_name: first_name,
        last_name: last_name,
        email: email
      )
    end

    private

    def email_already_used?
      Donor.exists?(email: email)
    end
  end
end
