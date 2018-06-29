module Partners
  class CreateOrUpdateCustomDonorQuestion < ApplicationCommand
    required do
      model :partner
      string :name
      string :title
      string :type
      boolean :required
    end

    optional do
      array :options, empty: true
    end

    def execute
      question = {
        name: name,
        title: title,
        type: type,
        required: required
      }
      question[:options] = options unless options.empty?

      Partners::DeleteCustomDonorQuestion.run(partner: partner, name: name)
      partner.donor_questions_schema['questions'] << question

      partner.update!(donor_questions_schema: partner.donor_questions_schema)
    end
  end
end
