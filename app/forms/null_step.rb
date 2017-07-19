class NullStep < Question
  def initialize
    super(nil)
  end

  def save
    true
  end
end
