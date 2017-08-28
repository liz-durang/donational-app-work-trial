class Wizard
  attr_reader :steps, :current_step

  def initialize(steps:, donor:)
    @steps = steps
    @donor = donor
    @current_step = steps.first
  end

  def current_step
    @current_step
  end
end
