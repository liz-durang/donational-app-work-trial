module Onboarding
  class LastStep < MultipleChoiceQuestion
    message "Thanks! Now it's time to take a look at your charity portfolio"

    allowed_response :create, 'Create my portfolio'

    def save
      Subscriptions::CreateOrReplaceSubscription.run!(
        donor: donor,
        donation_rate: donor.donation_rate,
        annual_income_cents: donor.annual_income_cents
      )
      true
    end
  end
end
