class NullStep < Step
  def initialize
    super(nil)
  end

  def save
    true
  end
end
