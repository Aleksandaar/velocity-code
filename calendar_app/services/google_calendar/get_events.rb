require "lib/retryable"
require "google/api_client"

module GoogleCalendar
  class GetEvents

    include Retryable

    class MissingCalendarId < Libary::InvalidArgumentException;
    end

    class PagingError < StandardError
      def message
        "Unhandled nextPageToken"
      end
    end

    def initialize (api_client, api_service)
      @api_client  = api_client
      @api_service = api_service
    end

    attr_reader :last_result

    def execute (calendar_id, options)
      raise MissingCalendarId if calendar_id.blank?
      response = get_events(calendar_id, options)

      if response.data["nextPageToken"].present?
        Bugsnag.notify(PagingError.new)
      end

      handle_events_response response
    end

    def last_result_timestamp
      if last_result.present?
        Time.parse(last_result.headers["date"])
      else
        nil
      end
    end

    private

    def get_events (calendar_id, options)
      @last_result = @api_client.execute(
         :api_method => @api_service.events.list,
         :parameters => get_events_params(calendar_id, options)
      )
    end

    def handle_events_response (response)
      case response.status
      when 200
        parse_events response
      when 401
        raise_response_error UserPrivilegesError, response
      when 403
        raise_response_error QuotaExceededError, response
      when 404
        raise_response_error ResourceNotFoundError, response
      when 410
        raise_response_error IncrementalQueryUnavailableError, response
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

    def get_events_params (calendar_id, options)
      params               = {
         "calendarId"   => calendar_id,
         "singleEvents" => "true",
         "showDeleted"  => "true",
         "orderBy"      => "startTime",
         "maxResults"   => "6000",
         "fields"       => "items(description,end,htmlLink,iCalUID,id,start,summary,updated,status)"
      }
      params["timeMin"]    = format_date(options[:range_start]) if options[:range_start].present?
      params["timeMax"]    = format_date(options[:range_end]) if options[:range_end].present?
      params["updatedMin"] = format_date(options[:updated_after]) if options[:updated_after].present?
      return params
    end

    def format_date (date)
      date.in_time_zone("UTC").strftime("%Y-%m-%dT%H:%M:%SZ")
    end

    def parse_events (response)
      items = response.data.items
      if items.present?
        events_excluding_all_day(items).map do |event|
          build_event(event)
        end.flatten
      else
        []
      end
    end

    def events_excluding_all_day(items)
      # Exclude all-day events
      items.select { |event| event.start.try(:date_time).present? }
    end

    def build_event(event)
      Event.new do |e|
        e.start_time  = event.start.date_time
        e.end_time    = event.end.date_time
        e.updated_at  = event.updated
        e.id          = event.id
        e.instance_id = generate_instance_id(event)
        e.title       = event.summary
        e.details     = event.description
        e.url         = event.html_link
        e.status      = event.status
      end
    end

    def generate_instance_id (event)
      "#{event.i_cal_uid}-#{event.start.date_time.to_i}-#{event.end.date_time.to_i}"
    end

  end
end
