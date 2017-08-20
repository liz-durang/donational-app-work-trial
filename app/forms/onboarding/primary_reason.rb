module Onboarding
  class PrimaryReason < QuickResponseStep
    message 'What is the main thing that you are looking for in a tool to help you donate?'

    allowed_response :alignment_with_beliefs, 'I want to discover charities that align with my values'
    allowed_response :most_impact,
      'I want to donate to charities that have the most impact',
      "We've consulted with experts to select charities that do the most with each dollar donated."
    allowed_response :give_what_i_should, 'I want to give the amount that I think I should (no more, no less!)'
    allowed_response :manage_donations, 'I want to manage all of my donations from one place (and make my life simpler at tax-time)'

    display_as :checkboxes

    def save
      true
    end

    def follow_up_message
      case response
      when :todo
        "Good answer!"
      end
    end
  end
end
