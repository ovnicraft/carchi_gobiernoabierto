class SetDebatesFinishedAt < ActiveRecord::Migration
  def self.up
    Debate.published.each do |d|
      d.finished_at = d.stages.last.ends_on.to_time.end_of_day
      d.save(callbacks:false) # para no ejecutar los after_save
    end
  end

  def self.down
  end
end
