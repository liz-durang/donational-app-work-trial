module ClientSideAnalytics
  extend ActiveSupport::Concern

  def track_analytics_event_via_browser(event, properties = {})
    flash[:analytics] ||= []
    flash[:analytics] << [event, properties]
  end
end
