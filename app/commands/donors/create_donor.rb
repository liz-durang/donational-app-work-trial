module Donors
  class CreateDonor < ApplicationCommand
    required do
      string :email
    end

    optional do
      string :first_name
      string :last_name
      string :entity_name
    end

    def validate
      validate_donor_email!
      validate_donor_name!
    end

    def execute
      Donor.create!(
        first_name: first_name,
        last_name: last_name,
        entity_name: entity_name,
        email: email
      )
    end

    private

    def email_already_used?
      Donor.exists?(email: email)
    end

    def validate_donor_email!
      return unless email_already_used?

      add_error(:donor, :email_already_used, 'The email is already in use')
    end

    def validate_donor_name!
      if entity_name.blank? && first_name.blank? && last_name.blank?
        add_error(:donor, :invalid_name, 'Either entity_name or first_name and last_name should be present')
      end
    end
  end
end
