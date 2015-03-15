class AddUrlToDebateEntities < ActiveRecord::Migration
  def self.up
    add_column :debate_entities, :url, :string
  end

  def self.down
    remove_column :debate_entities, :url
  end
end