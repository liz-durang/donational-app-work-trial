class ApplicationQuery
  class << self
    delegate :call, to: :new
  end
end
