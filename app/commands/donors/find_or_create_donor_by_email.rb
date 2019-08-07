module Donors
  class FindOrCreateDonorByEmail < ApplicationCommand
    required do
      string :email
      model :partner
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
      donor = Donor.find_or_initialize_by(email: email)
      donor.update!(first_name: first_name, last_name: last_name, entity_name: entity_name)
      Partners::AffiliateDonorWithPartner.run(donor: donor, partner: partner)
      donor
    end

    private

    def email_already_used?
      Donor.exists?(email: email)
    end

    def donor_associated_with_partner?(donor)
      Partners::GetPartnerAffiliationByDonorAndPartner.call(donor: donor, partner: partner).present?
    end

    def validate_donor_email!
      if email_already_used?
        donor = Donor.find_by(email: email)
        add_error(:donor, :email_already_used, 'The email is already in use') unless donor_associated_with_partner?(donor)
      end
    end

    def validate_donor_name!
      if entity_name.blank? && first_name.blank? && last_name.blank?
        add_error(:donor, :invalid_name, 'Either entity_name or first_name and last_name should be present')
      end
    end
  end
end
