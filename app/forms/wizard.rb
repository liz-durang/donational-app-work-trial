class Wizard
  attr_reader :steps, :current_step, :previous_step

  def initialize(steps:)
    @steps = steps
    restart!
  end

  def restart!
    @current_step = steps
    @previous_step = NullStep.new
  end

  def process_step!(params)
    next_step! if current_step.process!(params)
  end

  def next_step!
    @previous_step = current_step
    @current_step = current_step.next_step
  end

  def finished?
    current_step.nil?
  end
end
