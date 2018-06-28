module Partners
  class DeleteCustomDonorQuestion < ApplicationCommand
    required do
      model :partner
      string :name
    end

    def execute
      partner.donor_questions_schema['questions'].each_with_index do |question, index|
        partner.donor_questions_schema['questions'].delete_at(index) if question['name'] == name
      end

      partner.update!(donor_questions_schema: partner.donor_questions_schema)
    end
  end
end
