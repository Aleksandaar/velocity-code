require 'spec_helper'

describe Order do
  describe 'associations' do
    it { should belong_to :subscription }
    it { should belong_to :notification }

    context "subscription" do
      context "if a notification is provided" do
        let(:recurly_notification) { FactoryGirl.create :new_subscription_notification }

        it "should set the subscription" do
          o = Order.create(:notification => recurly_notification)
          o.subscription.should == recurly_notification.subscription
        end
      end

      context "if a notification is not provided" do
        context "a valid subscription is provided"
        let(:subscription) { FactoryGirl.create :recurly_subscription }

        it "should set the subscription" do
          o = Order.new(:subscription => subscription)
          o.subscription.should == subscription
          o.notification.should be_nil
        end
      end

      context "if a notification is removed" do
        context "order has a valid subscription and notification"
        let!(:subscription) { FactoryGirl.create :recurly_subscription }
        let!(:recurly_notification) { FactoryGirl.create :new_subscription_notification, subscription: subscription }
        let!(:order) { FactoryGirl.create :order, subscription: subscription, notification: recurly_notification }

        it "should clear the notification and maintain the subscription" do
          order.update_attribute :notification, nil
          order.subscription.should == subscription
          order.notification.should be_nil
        end
      end

    end
  end

  describe "validations" do
    it { should validate_presence_of :subscription }
  end

end
