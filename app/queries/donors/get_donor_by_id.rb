module Donors
  class GetDonorById  < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(id:)
      return nil if id.blank?

      @relation.find_by(id: id)
    end
  end
end
