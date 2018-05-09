# Allows a series of commands to be run in sequence, halting if any command fails
#
# Example:
#     outcome = Flow.new
#       .chain { TheFirstCommand.run(foo: 123) }
#       .chain { TheSecondCommand.run(baz: true) }
#       .chain { TheThirdCommand.run(some: :foo) }
#
#     if outcome.success?
#       redirect_to confirmation_page
#     else
#       redirect_to error_page, alert: outcome.errors
#     end
#
class Flow < ApplicationCommand
  def execute
    true
  end
end
