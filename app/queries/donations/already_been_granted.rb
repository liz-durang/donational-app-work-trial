module Donations
  class AlreadyBeenGranted < ApplicationQuery
    def call(contribution:)
      contribution.donations.where.not(grant: nil).exists?
    end
  end
end
