class CreateUbervuEntries < ActiveRecord::Migration
  def self.up
    create_table :ubervu_entries do |t|
      t.string :user_name, :user_url, :entry_url, :generator, :entry_type, :entry_id
      t.text :entry_content
      t.timestamp :entry_published_at
      t.timestamps
    end
    add_column :documents, :ubervued_at, :datetime
    add_column :videos, :ubervued_at, :datetime
  end

  def self.down
    drop_table :ubervu_entries
    remove_column :documents, :ubervued_at
    remove_column :videos, :ubervued_at
  end
end
