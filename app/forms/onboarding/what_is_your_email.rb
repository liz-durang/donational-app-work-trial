module Onboarding
  class WhatIsYourEmail < Step
    section "Let's get started"

    message "So that we can save your portfolio, what's your email?"

    display_as :email
    validates :response, presence: true, email: true
    validate :email_does_not_belong_to_another_existing_donor

    def email_does_not_belong_to_another_existing_donor
      return unless email_already_registered?
      errors.add(
        :email,
        "#{response} already has an account at Donational.org. <br/><br/> Do you want to #{sign_in_link}?"
      )
    end

    def save
      Donors::UpdateDonor.run!(donor: donor, email: response)
      ComingSoonNotificationMailer.test(response.to_s).deliver_later
    end

    def prepopulated_value
      donor.email
    end

    def sign_in_link
      ActionController::Base.helpers.link_to 'sign in', Rails.application.routes.url_helpers.new_sessions_path
    end

    def email_already_registered?
      Donor.where.not(id: donor.id).exists?(email: response)
    end

    class ComingSoonNotificationMailer < ActionMailer::Base
      def test(email)
        mail(
          from: 'no-reply@donational.org',
          to: 'hello@donational.org',
          subject: "#{email} started onboarding",
          body: 'A user entered the email during onboarding'
        )
      end
    end
  end
end
