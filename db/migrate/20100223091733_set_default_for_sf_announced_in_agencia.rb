class SetDefaultForSfAnnouncedInAgencia < ActiveRecord::Migration
  def self.up
    change_column :stream_flows, :announced_in_agencia, :boolean, :default => false
  end

  def self.down
  end
end
