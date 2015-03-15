class CreateExternalCommentsClients < ActiveRecord::Migration
  def self.up
    create_table :external_comments_clients do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :external_comments_clients
  end
end
