class MakeDebateEntityUrlTranslatable < ActiveRecord::Migration
  def self.up
    rename_column :debate_entities, :url, :url_es
    add_column :debate_entities, :url_eu, :string 
    add_column :debate_entities, :url_en, :string
  end

  def self.down
    remove_column :debate_entities, :url_en
    remove_column :debate_entities, :url_eu
    rename_column :debate_entities, :url_es, :url
  end
end