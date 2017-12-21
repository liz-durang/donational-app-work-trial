module ClientSideAnalytics
  extend ActiveSupport::Concern

  def send_client_side_analytics_event(event, properties = {})
    flash[:analytics] ||= []
    flash[:analytics] << [event, properties]
  end
end
