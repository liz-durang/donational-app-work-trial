module ClientSideAnalytics
  extend ActiveSupport::Concern

  # Allows us to trigger a browser-side analytics event from a controller
  # This is commonly used for triggering conversion pixels
  def track_analytics_event_via_browser(event, properties = {})
    flash[:analytics] ||= []
    flash[:analytics] << [event, properties]
  end
end
