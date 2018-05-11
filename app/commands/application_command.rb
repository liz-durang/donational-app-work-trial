class ApplicationCommand < Mutations::Command
  def chain(&other_operation)
    return if has_errors?

    chained_outcome = other_operation.call
    merge_errors(chained_outcome.errors) unless chained_outcome.success?

    self
  end
end
