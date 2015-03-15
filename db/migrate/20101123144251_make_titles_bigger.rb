class MakeTitlesBigger < ActiveRecord::Migration
  def self.up
    change_column :documents, :title_es, :string, :limit => 400
    change_column :documents, :title_eu, :string, :limit => 400
    change_column :documents, :title_en, :string, :limit => 400
    
    change_column :videos, :title_es, :string, :limit => 400
    change_column :videos, :title_eu, :string, :limit => 400
    change_column :videos, :title_en, :string, :limit => 400
    
  end

  def self.down
    change_column :documents, :title_es, :string
    change_column :documents, :title_eu, :string
    change_column :documents, :title_en, :string
    
    change_column :videos, :title_es, :string
    change_column :videos, :title_eu, :string
    change_column :videos, :title_en, :string
    
  end
end