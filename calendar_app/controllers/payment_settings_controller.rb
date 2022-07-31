require 'paypal-sdk-permissions'

module Settings
  class PaymentSettingsController < BaseController

    set_tab :settings
    set_section_nav "settings/section_nav"

    expose(:paypal_credentials) { current_user.paypal_credentials }

    # ===========
    # = Actions =
    # ===========

    # Initiate new authorisation.
    def update
      request_gateway.request_permissions
      if request_gateway.success?
        redirect_to request_gateway.grant_url
      else
        flash[:error] = request_gateway.error_message
        redirect_to settings_payment_path
      end
    end

    # Handle authorization response.
    def new
      icontext = interaction_context.merge({
         gateway: perform_gateway
      })
      run GetPaypalCredentialsInteraction, {}, icontext do
        redirect_to settings_payment_path
      end
    end

    # Delete the existing credentials.
    def destroy
      current_user.paypal_credentials.destroy
      redirect_to settings_payment_path
    end

    private

    def perform_gateway
      @perform_gateway ||= Payments::PaypalExpress::Authorization::Perform.new(
         params[:request_token],
         params[:verification_code]
      )
    end

    def request_gateway
      @request_gateway ||= Payments::PaypalExpress::Authorization::Request.new(
         new_settings_payment_credential_url
      )
    end

  end
end
