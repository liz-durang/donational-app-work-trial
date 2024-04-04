module Constants
  class GetTitles < ApplicationQuery
    def call
      %w[Mr Mrs Ms Mx].freeze
    end
  end
end
