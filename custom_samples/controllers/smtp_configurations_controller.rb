class SmtpConfigurationsController < ApplicationController

  layout "admin_websites"

  require_role 'admin'

  before_filter :authorize, :find_website_and_smtp_configuration

  def show
  end

  def edit
  end

  def update
    if @smtp_configuration.update_attributes(params[:smtp_configuration])
      flash[:notice] = "Email settings have been saved."
      redirect_to edit_website_smtp_configuration_path(@smtp_configuration)
    else
      render :action => :edit
    end
  end

  def send_test_email
    email_address = params[:email_address]

    begin

      TestMailer.test_email(email_address, current_user).deliver
      flash[:notice] = "Test email sent."

    rescue Exception => e
      flash[:notice] = "There was an error sending the email: #{e}"
    end

    redirect_to :back
  end

  protected

  def find_website_and_smtp_configuration
    @website = Website.find(params[:website_id])
    @smtp_configuration = @website.smtp_configuration
  end
end
