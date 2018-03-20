require 'segment/analytics'

module Analytics
  Engine ||= Segment::Analytics.new(write_key: ENV.fetch('SEGMENT_RUBY_WRITE_KEY'))

  class TrackEvent < ApplicationCommand
    required do
      string :user_id
      string :event
    end

    optional do
      hash :properties do
        duck :*
      end
    end

    def execute
      Engine.track(
        user_id: user_id,
        event: event,
        properties: properties
      )
    end
  end
end
