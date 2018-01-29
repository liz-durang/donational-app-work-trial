module Onboarding
  class PrimaryReasons < QuickResponseStep
    section "Your needs"

    message 'What are your main challenges to your charitable giving today?'

    allowed_response :identify_my_values,
      'Identifying which causes I care about',
      "Our advisors help you understand your goals and priorities, and align your donations to your values"
    allowed_response :make_the_most_impact,
      'Discovering which charities are making the most impact',
      "We've consulted with experts to select charities that have the greatest impact per each dollar donated."
    allowed_response :determine_how_much_can_give,
      'Understanding how much I can afford to give',
      "We'll help you determine how much you want to give, and help you stick to your budget"
    allowed_response :share_with_others,
      'Inspiring others to give',
      "You can share your charity portfolio with others, encouraging your friends to donate to causes that matter to you"
    allowed_response :monitoring_charities,
      'Ensuring that my donations are being used appropriately',
      "Donational works closely with industry experts to track every charity on the platform and ensure your dollars are being used for the greatest impact."
    # allowed_response :manage_giving_with_someone_else,
    #   'Managing my giving with someone else',
    #   "Bill and Melinda Gates have their own charitable foundation... Your family can too!"
    # allowed_response :tax_effective_donations,
    #   'Structuring donations in a tax efficient manner',
    #   "Your contributions through Donational are automatically pooled with other donations to minimize fees. At the end of the year, we'll send you a charitable giving receipt to help you do your taxes."

    display_as :checkboxes

    def save
      Donors::UpdateDonor.run!(donor, giving_challenges: response)
    end
  end
end
