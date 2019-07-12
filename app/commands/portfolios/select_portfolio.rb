module Portfolios
  class SelectPortfolio < ApplicationCommand
    required do
      model :donor
      model :portfolio
    end

    def execute
      SelectedPortfolio.transaction do
        deselect_existing_portfolios!
        SelectedPortfolio.create(donor: donor, portfolio: portfolio)
      end

      nil
    end

    private

    def deselect_existing_portfolios!
      SelectedPortfolio.where(donor: donor).update_all(deactivated_at: Time.zone.now)
    end

  end
end
