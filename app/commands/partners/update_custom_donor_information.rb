module Partners
  class UpdateCustomDonorInformation < ApplicationCommand
    required do
      model :donor
      model :partner
      hash :responses do
        string :*, max_length: 255, strip: true, strict: true
      end
    end

    def validate
      ensure_donor_is_affiliated_to_a_partner!
    end

    def execute
      responses.each do |question, response|
        partner_affiliation.custom_donor_info ||= {}
        partner_affiliation.custom_donor_info[question] = response
      end
      partner_affiliation.save!

      nil
    end

    private

    def partner_affiliation
      @partner_affiliation ||= PartnerAffiliation.find_by(donor: donor, partner: partner)
    end

    def ensure_donor_is_affiliated_to_a_partner!
      return if partner_affiliation.present?

      add_error(:donor, :not_affiliated_with_this_partner, 'The donor is not affiliated with this partner')
    end
  end
end
