module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_donor

    def connect
      self.current_donor = find_verified_donor || anonymous_donor
      logger.add_tags current_donor.id if current_donor
    end

    def disconnect
      # Any cleanup work needed when the cable connection is cut.
    end

    protected

    def session
      cookies
        .encrypted[Rails.application.config.session_options[:key]]
        .with_indifferent_access
    end

    def find_verified_donor
      Donors::FindOrCreateDonorFromAuth.run!(session[:userinfo])
    end

    def anonymous_donor
      OpenStruct.new(id: SecureRandom.hex(24))
    end
  end
end
