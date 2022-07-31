class Tenant < ActiveRecord::Base
  include SecureKey

  # =========
  # = Flags =
  # =========

  # If the publishing flag is set, the tenant is subject to
  # additional validation (of the invoicing settings). This
  # is set when the invoicing settings are provided as part
  # of the agreement publishing use case.

  attr_accessor :publishing

  # ===================================================== #
  #    Feature Flags
  # ===================================================== #

  #
  # Bit-field for feature flag configuration.
  # Managed by the active_flag gem.
  #
  # WARNING:
  #   The order of these fields is significant.
  #   DO NOT MODIFY the order of these flags.
  #   Only append new flags to the end.
  #
  flag :features, [
     :journeyman,
     :postmark,
     :stripe_subscriptions,
     :availability_calendar,
     :session_types,
     :google_notification_channels
  ]

  # ================
  # = Associations =
  # ================

  has_many :users
  has_many :subscriptions, :class_name => "Users::Subscription"
  has_many :trial_extensions, :class_name => "Account::TrialExtension"
  has_one :branding_settings
  belongs_to :affiliate

  # ==============
  # = Validation =
  # ==============

  validates :sitename, :presence => true, :uniqueness => true
  validates :paypal_email, email: true, allow_blank: true

  validates_format_of :sitename,
     :with    => /\A[a-z0-9]*(-[0-9]+-incinerated)?\z/,
     :message => "must be alphanumeric"

  validates_presence_of :paypal_email, :if => :publishing

  validates_presence_of :business_name, :if => :publishing

  # validates :invoice_number_counter, presence: true, numericality: true
  # validates_presence_of :invoice_number_counter
  # validates_numericality_of :invoice_number_counter

  validates_presence_of :tax1_name, :if => :tax1_active
  validates_presence_of :tax2_name, :if => :tax2_active

  validates_numericality_of :tax1_rate, :greater_than => 0, :if => :tax1_active, :message => "must be greater than zero"
  validates_numericality_of :tax2_rate, :greater_than => 0, :if => :tax2_active, :message => "must be greater than zero"

  validates_presence_of :currency

  has_secure_key :tapfiliate_external_id

  # ==================
  # = Account Status =
  # ==================

  def account_status
    Account::Status.for(self)
  end

  def verified?
    coach_user.present? && coach_user.email_verified_at.present?
  end

  # ===================================================== #
  #    Subscription
  # ===================================================== #

  def current_subscription
    active    = subscriptions.find { |s| s.cancelled_at.nil? }
    cancelled = subscriptions.find { |s| s.cancelled_at.present? }
    active || cancelled || Account::Trial.new(self)
  end

  def log_initial_subscription_payment
    unless initial_payment_at.present?
      update_attribute :initial_payment_at, Time.zone.now
    end
  end

  # ===========
  # = Queries =
  # ===========

  def coach
    @coach ||= Coach.where(:tenant_id => id).order(:id).first
  end

  def coach_user
    coach.present? ? coach.user : nil
  end

  def self.for_sitename (sitename)
    where(:sitename => sitename).first
  end

  # ==========
  # = PayPal =
  # ==========

  before_validation do
    self.paypal_email.strip! unless self.paypal_email.nil?
  end

  # ============
  # = Payments =
  # ============

  def total_payments
    Payment.total_for_tenant(self)
  end

  def total_sessions
    Session.where(tenant_id: id).count
  end

  # ===================================================== #
  #    Payment Integrations
  # ===================================================== #

  def allow_paypal_payments?
    paypal_credentials.present? || paypal_email.present?
  end

  def allow_stripe_payments?
    stripe_credentials.present?
  end

  def allow_stripe_subscriptions?
    allow_stripe_payments? && FEATURES.on?(:stripe_subscriptions, self)
  end

  # ===================================================== #
  #    Credentials
  # ===================================================== #

  def stripe_credentials
    Account::StripeCredentials.where(tenant_id: id).first
  end

  def paypal_credentials
    Account::PaypalCredentials.where(tenant_id: id).first
  end

  def express_checkout_credentials
    Account::PaypalCredentials.where(tenant_id: id).first
  end

  # ====================
  # = #currency_symbol =
  # ====================

  def currency_symbol
    Currency.new(currency).symbol
  end

  # ======================
  # = Invoicing Settings =
  # ======================

  before_validation :on => :create do
    self.invoice_number_counter ||= 1
  end

  after_initialize do
    self.currency ||= "USD"
  end

  validates :invoice_number_counter, presence: true, numericality: { only_integer: true }

  validate :invoice_counter_exceeds_existing_invoices

  def invoice_counter_exceeds_existing_invoices
    Multitenant.with_tenant self do
      n = Billing::Invoice.last_number
      unless invoice_number_counter.present? && invoice_number_counter > n
        s = (n == 0) ? "zero" : n.to_s
        errors.add(:invoice_number_counter, "must be greater than #{s}")
      end
    end
  end

  def has_tax_settings?
    self.tax1_active || self.tax2_active
  end

  def can_invoice?
    paypal_email.present? && business_name.present?
  end

  def tax_rates
    [].tap do |tax_rates|
      tax_rates << tax_rate(1) if tax1_active
      tax_rates << tax_rate(2) if tax2_active
    end
  end

  def tax_rate (index)
    if index == 1
      { name: tax1_name, rate: tax1_rate }
    elsif index == 2
      { name: tax2_name, rate: tax2_rate }
    else
      raise ArgumentError, "index must be 1 or 2"
    end
  end

  # ===================================================== #
  #    Incineration
  # ===================================================== #

  def incinerated?
    incinerated_at.present?
  end

  # ===================================================== #
  #    Branding Settings
  # ===================================================== #

  def has_profile_image?
    branding_settings.try(:profile_image).present?
  end

end
