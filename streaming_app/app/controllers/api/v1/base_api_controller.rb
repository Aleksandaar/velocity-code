module Api
  module V1
    class Api::V1::BaseApiController < ActionController::Base
      respond_to :json
      before_action :validate_json
      skip_before_filter :verify_authenticity_token

      rescue_from Exception do |e|
        Bugsnag.notify(e)
        Rails.logger.error e.message
        error(E_API, I18n.t('api.errors.internal_error'))
      end

      rescue_from CanCan::AccessDenied do |e|
        error(E_ACCESS_DENIED, I18n.t('api.errors.user_not_authorized'))
      end

      def validate_json
        begin
          JSON.parse(request.raw_post).deep_symbolize_keys
        rescue JSON::ParserError => e
          Bugsnag.notify(e)
          error E_INVALID_JSON, 'Invalid JSON received'
          return
        end
      end

      def error(code=E_INTERNAL,message="API Error")
        render :json=>
        {
           status: STATUS_ERROR,
           error_no: code,
           message: message
        }, :status=>500
      end

      # @param object - a Hash or an ActiveRecord instance
      def success(object={})
        # Serialize object automatically
        object = hash_for(object) unless object.instance_of?(Hash)

        render :json=>
        {
           status: STATUS_OK
        }.merge(object)
      end
    end
  end
end
