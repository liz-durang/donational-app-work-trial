module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_donor

    def connect
      self.current_donor = find_verified_donor || reject_unauthorized_connection
      logger.add_tags current_donor.id
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    def session
      cookies
        .encrypted[Rails.application.config.session_options[:key]]
        .with_indifferent_access
    end

    protected

    def find_verified_donor
      Donors::FindOrCreateDonorFromAuth.run!(session[:userinfo])
    end
  end
end
