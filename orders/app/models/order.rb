class Order < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :notification, :polymorphic => true 
  has_many :order_line_items, inverse_of: :order
  # inverse_of is necessary so that order_id validation does not fail on associated order when creating an order_line_item
  # for a new order using accepts_nested_attributes_for

  accepts_nested_attributes_for :order_line_items, :reject_if => lambda { |a| a[:catalog_product_id].blank? }, :allow_destroy => true

  validates_presence_of :subscription

  before_validation :set_subscription

  def to_label
    "#{id}"
  end

  alias_method :original_notification, :notification
  def notification
    original_notification rescue nil
  end

  private

  def set_subscription
    self.subscription_id = self.notification.subscription_id unless self.notification.nil?
  end

end
