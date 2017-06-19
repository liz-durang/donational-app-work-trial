class Wizard
  attr_reader :steps

  def initialize(steps)
    @current_step_id = 0
    @steps = steps
  end

  def first_step
    steps.first
  end

  def last_step
    steps.last
  end

  def current_step
    steps[@current_step_id]
  end

  def next_step!
    return nil if last_step?

    @current_step_id += 1
    current_step
  end

  def last_step?
    @current_step_id == steps.size - 1
  end
end
