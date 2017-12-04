module Contributions
  class CreateContribution < Mutations::Command
    required do
      model :portfolio
      integer :amount_cents
    end

    def execute
      contribution = Contribution.create!(
        portfolio: portfolio,
        amount_cents: amount_cents,
        scheduled_at: Time.now
      )

      ProcessContribution.run(contribution: contribution)

      nil
    end
  end
end
