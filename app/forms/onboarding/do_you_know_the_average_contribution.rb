module Onboarding
  class DoYouKnowTheAverageContribution < MultipleChoiceQuestion
    message 'Did you know that the average American gives 2.8% of their pretax annual income to charity?'
    message 'Does that surprise you?'

    allowed_response :yes, 'Yes'
    allowed_response :somewhat, 'A little bit'
    allowed_response :no, 'Not at all!'

    def save
      Donors::UpdateDonor.run!(donor, surprised_by_average_american_donation_rate: response)
    end
  end
end
