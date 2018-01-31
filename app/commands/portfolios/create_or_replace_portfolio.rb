require Rails.root.join('lib','mutations','decimal_filter')

module Portfolios
  class CreateOrReplacePortfolio < Mutations::Command
    required do
      model :donor
      string :contribution_frequency, default: 'once'
    end

    optional do
      integer :contribution_amount_cents, min: 0
    end

    def execute
      Portfolio.transaction do
        deactivate_existing_portfolios!
        Portfolio.create!(
          donor: donor,
          contribution_frequency: contribution_frequency,
          contribution_amount_cents: contribution_amount_cents
        )
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
