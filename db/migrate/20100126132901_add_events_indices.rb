class AddEventsIndices < ActiveRecord::Migration
  def self.up
    add_index :documents, [:type, :starts_at], :name => "index_documents_on_type_and_starst_at"
    add_index :schedule_events, [:schedule_id, :starts_at], :name => "index_schedule_events_on_schedule_and_starts_at"
  end

  def self.down
    remove_index :schedule_events, :name => :index_schedule_events_on_schedule_and_starts_at
    remove_index :documents, :name => :index_documents_on_type_and_starst_at
  end
end
