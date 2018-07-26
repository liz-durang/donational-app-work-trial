# Task to send reminders before future dated contributions
task send_reminder: :environment do
  Contributions::SendFutureDatedContributionsReminder.run
end
