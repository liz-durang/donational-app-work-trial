module Onboarding
  class DoYouKnowTheAverageContribution < QuickResponseStep
    section 'Your giving history'

    message 'Did you know that the average American gives 2.8% of their pretax annual income to charity?'
    message 'Does that surprise you?'

    allowed_response :yes, 'Yes'
    allowed_response :somewhat, 'A little bit'
    allowed_response :no, 'Not at all!'

    display_as :radio_buttons

    def save
      Donors::UpdateDonor.run!(donor, surprised_by_average_american_donation_rate: response)
    end

    def follow_up_message
      'Our aim is to make sure that your whatever you give, it is directed toward organizations that have the most impact.'
    end
  end
end
