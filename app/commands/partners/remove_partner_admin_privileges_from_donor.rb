module Partners
  class RemovePartnerAdminPrivilegesFromDonor < ApplicationCommand
    required do
      model :donor
      model :partner
    end

    def execute
      donor.partners.delete(partner)
      nil
    end
  end
end
