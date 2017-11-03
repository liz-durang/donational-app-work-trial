module Donors
  class GetDonorByUsername  < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(username:)
      return nil if username.blank?

      @relation.find_by(username: username)
    end
  end
end
