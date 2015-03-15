class AddEventsStreamingFor < ActiveRecord::Migration
  def self.up
    add_column :documents, :streaming_for, :string, :limit => 50
    
    execute "UPDATE documents SET streaming_for='irekia,agencia' WHERE streaming_live='t'"
  end

  def self.down
    remove_column :documents, :streaming_for
  end
end
