module Onboarding
  class ComingSoon < Question
    message "Thanks for making it this far!"
    message "There are a few more things we'd need to ask you, such as which cause areas matter to you most? (eg Poverty Action, Clean Water, Disaster Relief, Education, Environment & Climate Change, Animal Welfare)"
    message "However, we're still working on getting this platform ready for launch"
    message "If you'd like some one-on-one advice about your charitable giving plans, you can reach out to ian@donational.org"
    message "and to be kept up to date with our progress, let us know your email address below!"

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
