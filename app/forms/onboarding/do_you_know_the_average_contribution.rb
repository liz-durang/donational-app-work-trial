module Onboarding
  class DoYouKnowTheAverageContribution < QuickResponseStep
    section "Your giving goals"

    message 'Did you know that the average American gives 2.8% of their pretax annual income to charity?'
    message 'Does that surprise you?'

    allowed_response :yes, 'Yes'
    allowed_response :somewhat, 'A little bit'
    allowed_response :no, 'Not at all!'

    follow_up_message 'Our aim is to make sure that whatever you choose to give, it is directed toward organizations that have the most impact.'

    display_as :radio_buttons

    def save
      Donors::UpdateDonor.run!(donor, surprised_by_average_american_donation_rate: response)
    end
  end
end
