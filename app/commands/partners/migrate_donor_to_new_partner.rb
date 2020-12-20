module Partners
  class MigrateDonorToNewPartner < ApplicationCommand
    required do
      model :donor
      model :partner
    end

    def execute
      pipeline = Flow.new
      pipeline.chain {
        Partners::MigrateAffiliationToNewPartner.run(partner_affiliation: current_affiliation, partner: partner)
      }
      pipeline.chain {
        Contributions::MigrateSubscriptionToNewPartner.run(subscription: current_subscription, partner: partner)
      }

      outcome = pipeline.run
      nil
    end

    private

    def current_affiliation
      @current_affiliation = Partners::GetPartnerAffiliationByDonor.call(donor: donor)
    end

    def current_subscription
      @current_subscription = Contributions::GetActiveSubscription.call(donor: donor)
    end
  end
end
