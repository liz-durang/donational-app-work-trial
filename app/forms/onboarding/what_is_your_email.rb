module Onboarding
  class WhatIsYourEmail < Step
    section "Preparing your charity portfolio"

    message "We've done the research to ensure that every charity in your portfolio is making measurable impact to problems that are in need, and also can be solved through proven techniques"
    message "From what you've told us, we'll build a diverse and impactful portfolio of charities that represent your values."
    message "To see your portfolio, please let us know your email address below!"

    display_as :email
    validates :response, presence: true, email: true

    def save
      Donors::UpdateDonor.run!(donor, email: response)
      ComingSoonNotificationMailer.test(response.to_s).deliver_later
    end

    class ComingSoonNotificationMailer < ActionMailer::Base
      def test(email)
        mail(
          from: 'no-reply@donational.org',
          to: 'hello@donational.org',
          subject: "#{email} Completed onboarding",
          body: 'A user completed the coming-soon question'
        )
      end
    end
  end
end
