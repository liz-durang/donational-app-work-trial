module Partners
  class UpdateCustomDonorQuestions < ApplicationCommand
    required do
      model :partner
      array :donor_questions, class: Partner::DonorQuestion
    end

    def execute
      partner.donor_questions = donor_questions
      partner.save
    end
  end
end
