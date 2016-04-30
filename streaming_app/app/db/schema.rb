 ActiveRecord::Schema.define(version: 20150602120126) do
  create_table "sessions", force: :cascade do |t|
    t.string  "token",         limit: 255
    t.integer "user_id",       limit: 4
    t.string  "user_agent",    limit: 255
    t.integer "user_agent_id", limit: 4
  end

  add_index "sessions", ["token"], name: "index_sessions_on_token", unique: true, using: :btree

end