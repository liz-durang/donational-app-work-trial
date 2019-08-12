module Grants
  class VoidGrant < ApplicationCommand
    required do
      model :grant
    end

    def validate
      return if grant.voided_at.blank?
      add_error(:grant, :already_voided, 'The payment has already been voided')
    end

    def execute
      grant.update!(
        voided_at: Time.zone.now,
        processed_at: grant.processed_at || Time.zone.now 
      )
      mark_associated_donations_as_unpaid!
      nil
    end

    def mark_associated_donations_as_unpaid!
      Donation.where(grant: grant).update_all(grant_id: nil) 
    end
  end
end
