class AddTwitterCommentsToStatsCounters < ActiveRecord::Migration
  def change
    add_column :stats_counters, :user_comments, :integer
    add_column :stats_counters, :twitter_comments, :integer
    add_column :stats_counters, :not_twitter_comments, :integer
  end
end
