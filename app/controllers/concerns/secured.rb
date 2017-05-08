module Secured
  extend ActiveSupport::Concern

  included do
    before_action :ensure_logged_in!
  end

  def ensure_logged_in!
    redirect_to new_sessions_path unless logged_in?
  end
end
