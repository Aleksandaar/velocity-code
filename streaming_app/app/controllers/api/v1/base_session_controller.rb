module Api
  module V1
    class BaseSessionController < BaseApiController
      prepend_before_action :validate_session

      def current_user
        @current_user ||= @session.user
      end

      def current_session
        @session
      end

      def sign_in(user)
        @current_user = user
        @session.user_id = user.id
        @session.save
      end

      protected
        def validate_session
          session = params[:session].strip.slice(0,SESSION_TOKEN_LENGTH) if params[:session].present?
          s = (session.present? && session.length == SESSION_TOKEN_LENGTH) ? Session.find_by(token: session) : nil
          if !s
            error E_ACCESS_DENIED, 'Authentication required for this operation'
            return false
          end
          @session = s

          # Automatically sign out user if his account is not confirmed
          if current_user && !current_user.active_for_authentication?
            sign_out
            error E_INVALID_LOGIN, "User's email address is not confirmed"
            return false
          end
          true
        end

        def authenticate_user!
          unless current_user
            unauthorized!
            return false
          end
          true
        end

        def sign_out
          @current_user = nil
          @session.user_id = nil
          @session.save
        end

        def unauthorized!(msg = nil)
          error E_ACCESS_DENIED, msg || 'Unauthorized for this operation'
        end

        def ensure_current_user!
          sign_in @session.create_guest! unless current_user
          current_user
        end
    end
  end
end
