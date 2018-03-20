class ApplicationCommand < Mutations::Command
  def chain(other_command)
    merge_errors(other_command.errors) unless other_command.success?

    other_command
  end
end
