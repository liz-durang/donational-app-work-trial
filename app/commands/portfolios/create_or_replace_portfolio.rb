module Portfolios
  class CreateOrReplacePortfolio < ApplicationCommand
    required do
      model :donor
    end

    def execute
      Portfolio.transaction do
        deactivate_existing_portfolios!
        Portfolio.create!(donor: donor)
      end

      nil
    end

    private

    def deactivate_existing_portfolios!
      Portfolios::GetActivePortfolios
        .call(donor: donor)
        .update_all(deactivated_at: Time.zone.now)
    end

  end
end
