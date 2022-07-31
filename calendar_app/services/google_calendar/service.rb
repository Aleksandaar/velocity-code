require 'google/api_client'
require 'google_calendar/errors'
require 'google_calendar/api_config'

module GoogleCalendar
  class Service

    def initialize (auth_token)
      @auth_token = auth_token
      @api_config = ApiConfig.new(auth_token)
    end

    attr_accessor :auth_token
    attr_accessor :last_result

    def == (other)
      auth_token == other.auth_token
    end

    def calendars
      GetCalendars.new(@api_config.api_client, @api_config.api_service).execute
    end

    def events (calendar_id, options = {})
      get_events = GetEvents.new(@api_config.api_client, @api_config.api_service)
      get_events.execute(calendar_id, options).tap do
        @last_result = get_events.last_result
      end
    end

    def watch_events(calendar_id)
      watch_events = WatchEvents.new(@api_config.api_client, @api_config.api_service)
      response = watch_events.execute(calendar_id)
      
      rescue GoogleCalendar::WatchEvents::ResourceNotSupportedError
        # Google default calendars (for public events or similar) can't be watched
        nil
      rescue GoogleCalendar::ClientError => error
        Bugsnag.notify(error)
        raise
    end

    def unwatch_events(channel_id, resource_id)
      unwatch_events = UnwatchEvents.new(@api_config.api_client, @api_config.api_service)
      unwatch_events.execute(channel_id, resource_id)
      
      rescue GoogleCalendar::ClientError => error
        Bugsnag.notify(error)
        raise
    end

    def last_result_timestamp
      if last_result.present?
        Time.parse(last_result.headers["date"])
      else
        nil
      end
    end

    def client
      @api_config.api_client
    end

    def api
      @api_config.api_service
    end

  end

end
