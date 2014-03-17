require 'spec_helper'

describe OrdersController do

  shared_examples_for 'lists possible notifications for association' do
    describe "notifications that can be selected for this order" do
      # the only notifications that can be selected are ones that don't already have an order
      let!(:notification_with_order) { subscription.notifications.first }
      let!(:existing_order) { FactoryGirl.create :blank_order, notification: notification_with_order }
      let!(:notification_without_order) { subscription.notifications.second }

      it "assigns @notifications" do
        make_request
        subscription.notifications.length.should == 2

        assigns(:notifications).should == [notification_without_order]
      end
    end
  end

  describe "GET new" do
    let(:make_request) {
      get :new
    }

    context "Not signed in" do
      it_behaves_like "an admin-required action"
    end

    context "as Admin" do
      login_admin

      context "no subscription or notification is provided" do
        it "is an error" do
          expect { make_request }.to raise_error
        end
      end

      context "a notification is provided" do

        shared_examples_for 'assigns a new order as @order' do
          it "assigns @order" do
            make_request
            assigns(:order).should be_a_new(Order)
            assigns(:order).notification.should == notification
            assigns(:order).subscription.should == subscription
          end
        end

        context "RecurlyNotification" do
          let(:subscription) { FactoryGirl.create :recurly_subscription, :with_recurly_notifications }
          let(:notification) { subscription.recurly_notifications.first }

          let(:make_request) {
            get :new, recurly_notification_id: notification.id
          }

          it_behaves_like 'assigns a new order as @order'
          it_behaves_like 'lists possible notifications for association'
        end

        context "PaymentNotification" do
          let(:subscription) { FactoryGirl.create :paypal_subscription, :with_payment_notifications }
          let(:notification) { subscription.payment_notifications.first }

          let(:make_request) {
            get :new, payment_notification_id: notification.id
          }

          it_behaves_like 'assigns a new order as @order'
          it_behaves_like 'lists possible notifications for association'
        end
      end

      context "a subscription is provided" do
        let(:subscription) { FactoryGirl.create :recurly_subscription, :with_recurly_notifications }
        let(:notification) { nil }

        let(:make_request) {
          get :new, subscription_id: subscription.id
        }

        it_behaves_like 'assigns a new order as @order'
        it_behaves_like 'lists possible notifications for association'
      end

    end
  end


end




