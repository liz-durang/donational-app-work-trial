module Partners
  class AssignPartnerAdminPrivilegesToDonor < ApplicationCommand
    required do
      model :donor
      model :partner
    end

    def execute
      donor.partners << partner
      nil
    end
  end
end
