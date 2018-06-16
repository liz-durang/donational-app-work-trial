module Grants
  class ProcessGrant < ApplicationCommand
    required do
      model :grant
    end

    def validate
      return if grant.processed_at.blank?
      add_error(:grant, :already_processed, 'The payment has already been processed')
    end

    def execute
      Grant.transaction do
        chain do
          Grants::SendCheck.run(
            organization: grant.organization,
            amount_cents: grant.amount_cents
          )
        end

        grant.update!(processed_at: Time.zone.now)
      end

      nil
    end
  end
end
