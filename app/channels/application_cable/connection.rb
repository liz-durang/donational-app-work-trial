# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_donor

    def connect
      self.current_donor = find_verified_donor || reject_unauthorized_connection
      logger.add_tags current_donor.id if current_donor
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    protected

    def session
      cookies
        .encrypted[Rails.application.config.session_options[:key]]
        &.with_indifferent_access
    end

    def find_verified_donor
      donor_id = session&.[](:donor_id)
      return nil unless donor_id.present?

      Donors::GetDonorById.call(id: donor_id)
    end
  end
end
