module Onboarding
  class SupportExtremePovertyAlleviation < QuickResponseStep
    section "Your Values: Fighting extreme poverty"

    message 'Over 700 million people in our world live in extreme poverty (incomes of less than $2 per day)'
    message 'A majority of the global poor live in remote rural areas with limited access to basic needs like education, health care, electricity or even clean water.'
    message 'For many, escaping extreme poverty is only temporary, with food scarcity, economic/political shocks or an illness to a family member forcing them back below the poverty line.'
    message "Progress to reduce poverty *has* been effective, and if everyone in the developed world directed just 1% of their income to this issue, we'd be able to eradicate extreme poverty in our lifetime."
    message 'Is eradication of extreme poverty important to you?'

    allowed_response :yes, 'Yes'
    allowed_response :no, 'No, I have other priorities'

    display_as :radio_buttons

    def save
      true
    end
  end
end

# http://www.worldbank.org/en/topic/poverty/overview#1
