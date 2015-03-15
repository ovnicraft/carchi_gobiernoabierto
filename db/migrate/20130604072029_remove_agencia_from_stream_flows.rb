class RemoveAgenciaFromStreamFlows < ActiveRecord::Migration
  def self.up
    remove_column :stream_flows, :show_in_agencia
    remove_column :stream_flows, :announced_in_agencia
  end

  def self.down
    add_column :stream_flows, :announced_in_agencia, :boolean, :default => false
    add_column :stream_flows, :show_in_agencia, :boolean,      :default => false
  end
end
