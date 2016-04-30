require 'socket'

module Api
  module V1
    SESSION_TOKEN_LENGTH = 22

    STATUS_OK = 'ok'
    STATUS_ERROR = 'error'

    E_INVALID_JSON = 1
    E_INVALID_SESSION = 2
    E_ACCESS_DENIED = 3
    E_INTERNAL = 4
    E_SIGNUP_FAILED = 5
    E_INVALID_LOGIN = 6
    E_RESOURCE_NOT_FOUND = 7
    E_INVALID_PARAM = 8
    E_API = 9
    E_METHOD_NOT_FOUND = 10
    E_UNSUPPORTED = 11
    E_USER_BLOCKED = 12
    E_USER_UNCONFIRMED = 13
    E_REMOTE_API = 14
    E_TOS_NOT_ACCEPTED = 15
    E_USER_GUEST_ACCOUNT = 16
    E_USER_CONFIRMED = 17

    VERSION = '1.1.0'

    EXAMPLE_API_URL = ENV.fetch("EXAMPLE_API_URL")

    PAGINATION_DEFAULT_LIMIT = 20
    PAGINATION_MAX_LIMIT = 50

    class CatchJsonParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue ActionDispatch::ParamsParser::ParseError => error
          Bugsnag.notify(error)
          error_output = 'There was a problem in the JSON you submitted'
          return [
            500,
            { 'Content-Type' => 'application/json' },
            [{ status: STATUS_ERROR, error_no: E_INVALID_JSON, message: error_output }.to_json]
          ]
        end
      end
    end

  end
end
