module GoogleCalendar

  class MaxRetriesExceededError < StandardError
    # Calendar sync will be aborted because the maximum number of retries for
    # this calendar has been reached. Note: this is not a TransmissionError
    # like most of the exceptions defined here.
  end

  class TransmissionError < StandardError
    # Base error class for exceptions occurring while attempting to
    # communicate with the remote calendar service.

    include Bugsnag::MetaData

    def initialize (data = {})
      self.bugsnag_meta_data = data
    end

    def data
      bugsnag_meta_data
    end

    def message
      if data.present?
        begin
          msg = data.fetch(:body).fetch('error').fetch('message')
          "#{msg} (#{data[:status]})"
        rescue KeyError, NoMethodError
          "#{self.class.name} (#{data[:status]})"
        end
      else
        super
      end
    end
  end

  # ============================================================ #
  #   400..499
  # ============================================================ #

  class ClientError < TransmissionError
    # Base class for 400 errors caused by bad request.
  end

  class InvalidGrant < ClientError
    # The OAuth token is invalid.
    # Currently used in token management.
  end

  class UnauthorizedException < ClientError
    # Status code 401.
    # Currently used in token management.
    # Can probably be combined with UserPrivilegesError.
    # Service call failed because it was not authorized, or because the token has expired.
  end

  class UserPrivilegesError < ClientError
    # Status code 401.
    # Service call failed because the user does not have the necessary privileges.
  end

  class QuotaExceededError < ClientError
    # Status code 403.
    # Service call failed because we exceeded our daily API usage quota.
    # https://developers.google.com/google-apps/calendar/v3/errors
  end

  class RateLimitExceededError < ClientError
    # Status code 403.
    # Service call failed because we sent too many requests too quickly.
    # https://developers.google.com/calendar/v3/errors#403_user_rate_limit_exceeded
  end

  class ResourceNotFoundError < ClientError
    # Status code 404.
    # This could mean that either the calendar or the event we
    # are trying to update does not exist.
    # https://developers.google.com/google-apps/calendar/v3/errors
  end

  class IncrementalQueryUnavailableError < ClientError
    # Status code 410.
    # The updatedMin parameter (incremental query) is too far in the past.
    # We need to try the query again with a full update.
    # https://developers.google.com/google-apps/calendar/v3/errors
  end

  # ============================================================ #
  #   500..599
  # ============================================================ #

  class BackendError < TransmissionError
    # Base class for 500 errors, caused by server issues.
  end

  class ServiceUnavailableException < BackendError
    # The service is temporarily unavailable.
    # May be due to network capacity or exceeding resource limits.
    # https://developers.google.com/admin-sdk/calendar-resource/limits
  end


end