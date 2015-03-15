class CreateStatsCounters < ActiveRecord::Migration
  def change
    create_table :stats_counters do |t|
      t.integer  :countable_id
      t.string   :countable_type
      t.string   :countable_subtype
      t.datetime :published_at
      t.integer  :department_id
      t.integer  :organization_id
      t.integer  :area_id
      t.integer  :comments
      t.integer  :official_comments
      t.integer  :answer_time_in_seconds
      t.integer  :arguments
      t.integer  :in_favor_arguments
      t.integer  :against_arguments
      t.integer  :votes
      t.integer  :positive_votes
      t.integer  :negative_votes
      t.timestamps
    end
    add_index :stats_counters, :countable_type
    add_index :stats_counters, :department_id
    add_index :stats_counters, :area_id
  end
end
