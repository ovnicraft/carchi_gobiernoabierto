class AddLAttendsFiledForEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :l_attends, :boolean, :default => false
    add_column :schedule_events, :l_attends, :boolean, :default => false
    
    if s = Schedule.find_by_short_name('Lehendakari')
      s.events.each do |e|
        e.update_attribute(:l_attends, true)
      end
    end
  end

  def self.down
    remove_column :schedule_events, :l_attends
    remove_column :documents, :l_attends
  end
end
