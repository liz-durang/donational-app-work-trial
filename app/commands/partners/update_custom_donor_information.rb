module Partners
  class UpdateCustomDonorInformation < ApplicationCommand
    required do
      model :donor
      model :partner
      hash :responses do
        string :*, max_length: 255, strip: true, strict: true, empty: true
      end
    end

    def validate
      ensure_donor_is_affiliated_to_a_partner!
      ensure_all_required_questions_are_answered!
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

    def ensure_all_required_questions_are_answered!
      responses.each do |question, response|
        donor_question = partner.donor_questions&.select { |q| question == q.name }&.first
        if donor_question&.required && response.blank?
          add_error(question.to_sym, :required_question, "#{donor_question.title.html_safe} is required.")
        end
      end
    end
  end
end
