require 'spec_helper'

describe "Orders" do

  context "for a specific RecurlyNotification" do
    let(:subscription) { FactoryGirl.create(:recurly_subscription, :with_recurly_notifications) }
    let(:recurly_notification) { subscription.recurly_notifications.first }

    before { login_admin }

    context "if no order exists" do
      it "can create an Order" do
        visit recurly_notification_path(recurly_notification)
        current_path.should == "/recurly_notifications/#{recurly_notification.id}"

        page.should have_content "No order exists."

        click_link 'Create New Order'
        current_path.should == "/orders/new"

        page.should have_content subscription.to_label
        page.should have_select 'order_notification_id',
                                options: [""] + subscription.notifications.without_order.map(&:to_label),
                                selected: recurly_notification.to_label

        click_button 'Create Order'
        current_path.should == "/orders/#{Order.last.id}"

        page.should have_content "Notification: #{recurly_notification.to_label}"
        page.should have_content "Subscription: #{subscription.to_label}"
      end
    end

    context "If an order exists" do
      before do
        recurly_notification.create_order
        visit recurly_notification_path(recurly_notification)
        current_path.should == "/recurly_notifications/#{recurly_notification.id}"
      end

      it "does not allow creation of another order" do
        within ".order-show" do
          page.should_not have_link 'New Order'
        end
      end

      it "allows to edit the order" do
        within ".order-show" do
          page.should have_content "Order ID: #{recurly_notification.order.id}"
          click_link "Edit"
        end

        current_path.should == "/orders/#{recurly_notification.order.id}/edit"
      end
    end
  end


end