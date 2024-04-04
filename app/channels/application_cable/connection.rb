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
      Donors::GetDonorById.call(id: session[:donor_id])
    end
  end
end
