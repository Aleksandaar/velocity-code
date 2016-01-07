class ApplicationController < ActionController::Base
  include AuthenticationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  before_action :http_authenticate, if: -> { %w{dev.example.com staging.example.com}.include?(request.host) }
  before_action :store_location, if: -> { request.get? && !devise_controller? }
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    Bugsnag.notify(exception)

    respond_to do |format|
      format.json do
        render json: { errors: [{ title: exception.message}] }, status: 403
      end
      format.all do
        redirect_to root_path, alert: exception.message
      end
    end
  end

  def process_object(success_message)
    status, message = begin
      yield

      [200, success_message]
    rescue => ex
      [422, t('errors.messages.database')]
    end

    render status: status, json: { message: message }
  end

  private
    def http_authenticate
      authenticate_or_request_with_http_basic do |username, password|
        username == 'example' && password == 'example123'
      end
    end

    # Devise hooks
    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :terms_of_service) }
    end

    def after_sign_in_path_for(resource)
      request.env['omniauth.origin'] || stored_location_for(resource) || root_path
    end

    def store_location
      store_location_for :user, request.fullpath
    end
end
