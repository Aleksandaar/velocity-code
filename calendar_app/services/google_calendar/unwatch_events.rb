require "lib/retryable"
require "google/api_client"

module GoogleCalendar
  class UnwatchEvents

    include Retryable

    class MissingChannelId < Libary::InvalidArgumentException;
    end

    class MissingResourceId < Libary::InvalidArgumentException;
    end

    def initialize (api_client, api_service)
      @api_client  = api_client
      @api_service = api_service
    end

    def execute(channel_id, resource_id)
      raise MissingChannelId if channel_id.blank?
      raise MissingResourceId if resource_id.blank?

      retry_on_exception [Google::APIClient::ServerError, Google::APIClient::TransmissionError] do
        response = unwatch_events(channel_id, resource_id)
        response_data = handle_events_response response
      end
    end


    private

    def unwatch_events(channel_id, resource_id)
      @api_client.execute(
         api_method: @api_service.channels.stop,
         body_object: get_body_object(channel_id, resource_id)
      )
    end

    def handle_events_response (response)
      case response.status
      when 204
        parse_notification_channel response
      when 401
        raise_response_error UserPrivilegesError, response
      when 403
        raise_response_error QuotaExceededError, response
      when 404
        raise_response_error ResourceNotFoundError, response
      when 500
      when 501
      when 502
      when 503
        raise_response_error ServiceUnavailableException, response
      else
        raise_response_error TransmissionError, response
      end
    end

    def raise_response_error (exception_class, response)
      raise exception_class.new(status: response.status, body: response.body)
    end

    def get_events_params(calendar_id)
      {
        calendarId: calendar_id,
      }
    end

    def get_body_object(channel_id, resource_id)
      {
        id: channel_id,
        resourceId: resource_id
      }
    end

    def parse_notification_channel(response)
      response.data
    end
  end
end
