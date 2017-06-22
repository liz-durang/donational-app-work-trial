module Questions
  class ComingSoon < EmailQuestion
    message "Thanks for taking a look"
    message "We're still working on getting this platform ready for launch."
    message "If you'd like to be kept up to date with our progress, let us know your email address"

    def save(response)
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
