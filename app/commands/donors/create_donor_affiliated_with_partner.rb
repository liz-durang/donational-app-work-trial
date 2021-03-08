module Donors
  class CreateDonorAffiliatedWithPartner < ApplicationCommand
    required do
      string :email
      model :partner
    end

    optional do
      model :campaign
      string :first_name, strip: true
      string :last_name, strip: true
      string :entity_name
      string :title, strip: true
      string :house_name_or_number, strip: true
      string :postcode
      boolean :uk_gift_aid_accepted
      string :referred_by_donor_id
    end

    def validate
      ensure_email_not_used!
      ensure_name_presence!
    end

    def execute
      donor = Donor.create!(creatable_attributes)

      Partners::AffiliateDonorWithPartner.run(
        donor: donor,
        partner: partner,
        campaign: campaign,
        referred_by_donor_id: referred_by_donor_id
      )

      donor
    end

    private

    # Validations
    def ensure_email_not_used!
      return unless email_already_used?

      add_error(:donor, :email_already_used, 'The email has already been taken')
    end

    def ensure_name_presence!
      return if entity_name.present? || (first_name.present? && last_name.present?)

      add_error(:donor, :invalid_name, 'Either entity name or first name and last name should be present')
    end

    # Methods
    def email_already_used?
      Donor.exists?(email: email, deactivated_at: nil)
    end

    def creatable_attributes
      inputs.except(:partner, :campaign, :referred_by_donor_id)
    end
  end
end
