class ContributionsSummaryMailer < ApplicationMailer
  def notify
    @contributions = params[:contributions].sort_by(&:processed_at)
    @organizations = @contributions.flat_map { |c| c.organizations }.uniq
    @total_contributions_cents = @contributions.sum(&:total_charges_cents)
    @year = params[:year]
    @partner = params[:partner]
    @partner_name = params[:partner].try(:name) || "Donational.org"
    @donor = params[:donor]
    currency = Partners::GetPartnerForDonor.call(donor: @donor)&.currency || params[:partner].try(:currency)
    @currency = Money::Currency.new(currency)
    @currency_downcase = params[:partner]&.currency&.downcase || 'usd'

    Time.use_zone(@donor.time_zone) do
      mail(
        to: @donor.email,
        from: "Donational Receipts <receipts@donational.org>",
        reply_to: "support@donational.org",
        subject: "It's Tax-Time! Here is your #{@partner_name} contribution summary for #{@year}"
      )
    end
  end
end
