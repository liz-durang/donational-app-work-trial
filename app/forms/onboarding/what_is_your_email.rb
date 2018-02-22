module Onboarding
  class WhatIsYourEmail < Step
    section "Let's get started"

    message "So that we can save your progress along the way, what's your email?"

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
