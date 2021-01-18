module Portfolios
  class UnarchiveManagedPortfolio < ApplicationCommand
    required do
      model :managed_portfolio
    end

    def execute
      managed_portfolio.update!(hidden_at: nil)

      nil
    end
  end
end
