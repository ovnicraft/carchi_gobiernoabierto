class CreateScheduleEvents < ActiveRecord::Migration
  def self.up
    create_table :schedule_events do |t|
      t.references :schedule
      t.string     :title, :null => false
      t.text       :body
      t.boolean    :draft, :default => true
      t.datetime   :starts_at, :null => false
      t.datetime   :ends_at, :null => false
      t.string     :place, :city
      t.string     :speaker
      t.decimal    :lat, :lng
      t.string     :location_for_gmaps, :limit => 500
      t.string     :state, :limit => 30
      t.integer    :staff_alert_version, :null => false, :default => 0
      t.integer    :created_by
      t.integer    :updated_by
      t.timestamps
    end
  end

  def self.down
    drop_table :schedule_events
  end
end
