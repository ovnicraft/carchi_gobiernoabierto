class AddAgendaControlToPolitician < ActiveRecord::Migration
  def self.up
    add_column :users, :politician_has_agenda, :boolean
    Politician.all.each do |politician|
      politician.update_attribute(:politician_has_agenda, true)
    end
  end

  def self.down
    remove_column :users, :politician_has_agenda
  end
end