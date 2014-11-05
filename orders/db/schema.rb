ActiveRecord::Schema.define(:version => 20140129233712) do

  create_table "order_line_items", :force => true do |t|
    t.integer  "order_id"
    t.integer  "catalog_product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_line_items", ["catalog_product_id"], :name => "index_order_line_items_on_catalog_product_id"
  add_index "order_line_items", ["order_id"], :name => "index_order_line_items_on_order_id"

  create_table "orders", :force => true do |t|
    t.integer  "notification_id"
    t.string   "notification_type"
    t.integer  "subscription_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["notification_id"], :name => "index_orders_on_notification_id"
  add_index "orders", ["subscription_id"], :name => "index_orders_on_subscription_id"

  create_table "payment_notifications", :force => true do |t|
    t.text     "params"
    t.integer  "subscription_id"
    t.string   "status"
    t.string   "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_type"
  end

  add_index "payment_notifications", ["subscription_id"], :name => "index_payment_notifications_on_subscription_id"


  create_table "subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.string   "chargify_subscription_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.string   "how_heard"
    t.string   "gender"
    t.integer  "age"
    t.integer  "referrer_id"
    t.string   "random_id"
    t.integer  "product_id"
    t.integer  "reflink_id"
    t.boolean  "is_gift"
    t.text     "notes"
    t.string   "payment_type"
    t.integer  "past_subscription_id"
    t.string   "info_update_uuid"
    t.datetime "recurly_invitation_date"
    t.integer  "buyer_id"
    t.integer  "recipient_id"
    t.string   "coupon_code"
  end

  add_index "subscriptions", ["buyer_id"], :name => "index_subscriptions_on_buyer_id"
  add_index "subscriptions", ["info_update_uuid"], :name => "index_subscriptions_on_info_update_uuid"
  add_index "subscriptions", ["past_subscription_id"], :name => "index_subscriptions_on_past_subscription_id"
  add_index "subscriptions", ["product_id"], :name => "index_subscriptions_on_product_id"
  add_index "subscriptions", ["recipient_id"], :name => "index_subscriptions_on_recipient_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "chargify_customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end