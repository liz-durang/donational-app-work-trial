module Partners
  class AdminsController < ApplicationController
    include Secured
    before_action :ensure_donor_has_permission!

    def create
      Partners::AssignPartnerAdminPrivilegesToDonor.run(donor: donor, partner: partner)
      flash[:success] = "Admin Privileges Granted"
      redirect_to edit_partner_donor_path(partner, donor)
    end

    def update
      Partners::RemovePartnerAdminPrivilegesFromDonor.run(donor: donor, partner: partner)
      flash[:success] = "Admin Privileges Revoked"
      redirect_to edit_partner_donor_path(partner, donor)
    end

    private

    def ensure_donor_has_permission!
      unless current_donor.partners.exists?(id: partner.id)
        flash[:error] = "Sorry, you don't have permission to grant admin privileges for this partner."
        redirect_to edit_partner_donor_path(partner, donor)
      end
    end

    def partner
      @partner = Partners::GetPartnerById.call(id: params[:partner_id])
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:donor_id])
    end
  end
end
