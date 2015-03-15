class CreateLinks < ActiveRecord::Migration
  def self.up
    add_column :documents, :url, :string
  end

  def self.down
    remove_column :documents, :url
  end
end
