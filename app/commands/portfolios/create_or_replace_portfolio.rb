module Portfolios
  class CreateOrReplacePortfolio < ApplicationCommand
    required do
      model :donor
    end

    def execute
      SelectPortfolio.run(
        donor: donor,
        portfolio: Portfolio.create!(creator: donor)
      )

      nil
    end
  end
end
