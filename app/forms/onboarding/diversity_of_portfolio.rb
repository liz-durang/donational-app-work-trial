module Onboarding
  class DiversityOfPortfolio < QuickResponseStep
    section "Your giving goals"

    message "Is it more important to you to make a focused impact (donating to a few charities), or to make a broad impact (donating to many charities)?"

    subtitle "I want to my portfolio to be"

    display_as :text_scale

    allowed_response :focused, "A few charities"
    allowed_response :mixed, "Mixed"
    allowed_response :broad, "Many charities"

    def save
      Donors::UpdateDonor.run!(donor, portfolio_diversity: response)
    end
  end
end
