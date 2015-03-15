class Stats::FS < ActiveRecord::Base
  self.table_name = 'stats_fs'
  self.primary_key = 'created_at'

  def self.mpg
    self.first.mpg if self.first
  end

  def self.mp3
    self.first.mp3 if self.first
  end
end
