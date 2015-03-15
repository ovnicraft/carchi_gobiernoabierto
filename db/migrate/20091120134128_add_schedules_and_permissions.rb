class AddSchedulesAndPermissions < ActiveRecord::Migration
  def self.up
    ["Agenda Lehendakari", "Agenda PSE"].each do |name|
      s = Schedule.create(:name => name, :short_name => name.split(" ").last)
      Admin.where("email ilike '%efaber%'").each do |u|
        s.users << u
      end
      s.save
    end
  end

  def self.down
    Schedule.destroy_all
  end
end
