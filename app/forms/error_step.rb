class ErrorStep < Question
  def initialize
    super(nil)
  end

  def follow_up_message
    "We had a little trouble understanding you. Let's try again."
  end
end
