class EmailQuestion < Question
  def valid?(value)
    value.include?('@')
  end
end
