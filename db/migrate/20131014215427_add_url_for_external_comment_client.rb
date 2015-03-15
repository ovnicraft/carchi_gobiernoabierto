class AddUrlForExternalCommentClient < ActiveRecord::Migration
  def self.up
    add_column :external_comments_clients, :url, :string
  end

  def self.down
    remove_column :external_comments_clients, :url
  end
end