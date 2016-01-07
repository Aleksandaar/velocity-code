class CreateGroupEvents < ActiveRecord::Migration
  def change
    create_table :group_events do |t|
      t.string :name
      t.text :description
      t.string :location
      t.date :start_date
      t.date :end_date
      t.integer :duration
      t.integer :status, default: 0
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
