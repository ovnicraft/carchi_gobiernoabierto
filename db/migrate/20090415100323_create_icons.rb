class CreateIcons < ActiveRecord::Migration
  def self.up
    create_table :icons do |t|
      t.string      :name
      t.string      :description, :limit => '2000'
      t.string      :photo_file_name
      t.string      :photo_content_type
      t.integer     :photo_file_size
      t.datetime    :photo_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :icons
  end
end
