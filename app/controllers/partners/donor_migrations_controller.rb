module Partners
  class DonorMigrationsController < ApplicationController
    include Secured
    before_action :ensure_donor_has_permission!

    def create
      outcome = Partners::MigrateDonorToNewPartner.run(donor: donor, partner: destination_partner)

      if outcome.success?
        flash[:success] = "Donor Migrated Successfully"
        redirect_to edit_partner_donor_path(destination_partner, donor)
      else
        flash[:error] = outcome.errors.message_list.join("\n")
        redirect_to edit_partner_donor_path(source_partner, donor)
      end
    end

    private

    def ensure_donor_has_permission!
      unless current_donor.partners.exists?(id: source_partner.id) && current_donor.partners.exists?(id: destination_partner.id)
        flash[:error] = "Sorry, you don't have permission to migrate donors for this partner."
        redirect_to edit_partner_donor_path(source_partner, donor)
      end
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:donor_id])
    end

    def source_partner
      @source_partner = Partners::GetPartnerById.call(id: params[:source_partner_id])
    end

    def destination_partner
      @destination_partner = Partners::GetPartnerById.call(id: params[:destination_partner_id])
    end
  end
end
