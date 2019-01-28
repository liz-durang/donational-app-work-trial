module Donors
  class SendAnnualContributionSummary < ApplicationCommand
    required do
      model :donor
      integer :year
    end

    def execute
      ContributionsSummaryMailer.with(
        donor: donor,
        year: year,
        contributions: annual_contributions,
        partner: affiliated_partner
      ).notify.deliver_now
    end

    def validate
      return unless annual_contributions.empty?
      add_error(:donor, :no_contributions_within_period, 'There are no annual contributions recorded for this donor')
    end

    private

    def affiliated_partner
      Partners::GetPartnerForDonor.call(donor: donor)
    end

    def annual_contributions
      @annual_contributions ||= Contributions::GetContributionsForYear.call(donor: donor, year: year)
    end
  end
end
