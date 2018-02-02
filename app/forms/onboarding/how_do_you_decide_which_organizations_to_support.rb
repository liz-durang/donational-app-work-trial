module Onboarding
  class HowDoYouDecideWhichOrganizationsToSupport < QuickResponseStep
    section "What's important to you"

    message 'There are many non-profits that you could support.'
    message 'What are the reasons you would choose to give to some charities over others?'

    allowed_response :aligned_with_my_values, 'Alignment with my beliefs and values'
    allowed_response :high_impact, 'Makes the highest impact'
    allowed_response :interest_in_the_cause_area, 'My interest in the cause area'
    allowed_response :firsthand_experience, 'First-hand experience with the charity'
    allowed_response :name_brand, 'Recognizable or reputable brand'
    allowed_response :non_profit_rankings, 'Non-profit report rankings'
    allowed_response :recommendation, 'Friend or family recommendation'
    allowed_response :belong_to_a_similar_minded_community, 'Part of a similar-minded community'
    # allowed_response :become_an_expert, 'I want to become an expert on the issue area'

    display_as :tags

    def save
      Donors::UpdateDonor.run!(donor, reasons_why_i_choose_an_organization: response)
    end
  end
end
