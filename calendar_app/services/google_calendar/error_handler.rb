module GoogleCalendar
  #
  # Responsible for raising the appropriate exception type
  # based on the HTTP response received from the Google
  # Calendar API.
  #
  # See https://developers.google.com/calendar/v3/errors#403_daily_limit_exceeded
  #
  
  class ErrorHandler
    def handle_response (status, body)
      if status == 404
        raise ResourceNotFoundError.new(status: status, body: body)

      elsif status == 403 && error_message(body) == "Daily Limit Exceeded"
        raise QuotaExceededError.new(status: status, body: body)

      elsif status == 403 && error_message(body) == "Rate Limit Exceeded"
        raise RateLimitExceededError.new(status: status, body: body)

      elsif status != 200
        raise TransmissionError.new(status: status, body: body)

      end
    end

    private

    def error_message (body)
      body["error"]["message"]
    end
  end
end