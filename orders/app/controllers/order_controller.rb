class OrdersController < ApplicationController
  before_filter :admin_page
  before_filter :load_associations

  def load_associations
    if params[:payment_notification_id]
      @notification = PaymentNotification.find_by_id(params[:payment_notification_id])
      @subscription = @notification.subscription
    elsif params[:recurly_notification_id]
      @notification = RecurlyNotification.find_by_id(params[:recurly_notification_id])
      @subscription = @notification.subscription
    elsif params[:subscription_id]
      @subscription = Subscription.find(params[:subscription_id])
    end

    if @subscription
      @orders = @subscription.orders.order("created_at DESC")
    else
      @orders = Order.scoped.order("created_at DESC")
    end
  end

  # GET /orders
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /orders/1
  def show
    @order = @orders.find_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /orders/new
  def new
    @order = @orders.build
    @order.notification = @notification if @notification
    @notifications = @order.subscription.notifications.without_order
    @order.order_line_items.build  

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /orders/1/edit
  def edit
    @order = @orders.find_by_id(params[:id])
    @subscription = @order.subscription
    @notification = @order.notification
    @notifications = @order.subscription.notifications.without_order_including_notification(@notification)
    @order.order_line_items.build  
  end

  # POST /orders
  def create
    @order = @orders.build(params[:order])

    if @order.notification_id
      @order.notification_type = (@order.subscription.uses_recurly? ? "RecurlyNotification" : "PaymentNotification")
    end

    @subscription = @order.subscription
    @notification = @order.notification
    @notifications = @order.subscription.notifications.without_order_including_notification(@notification) rescue []

    respond_to do |format|
      if @order.save
        format.html { redirect_to(@order, :notice => 'Order was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /orders/1
  def update
    @order = @orders.find_by_id(params[:id])

    if params[:order][:notification_id]
      params[:order][:notification_type] = (@order.subscription.uses_recurly? ? "RecurlyNotification" : "PaymentNotification")
    end

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to(@order, :notice => 'Order was successfully updated.') }
      else
        @order.reload
        @subscription = @order.subscription
        @notification = @order.notification
        @notifications = @order.subscription.notifications.without_order_including_notification(@notification) if @subscription
        format.html { render :action => "edit" }
      end
    end
  end

  # should only allow destroy if it has no payment and no items
  #def destroy
  #end

  def admin_page
    if admin_signed_in?
      @is_admin_page = true
    else
      redirect_to root_url
    end
  end
end