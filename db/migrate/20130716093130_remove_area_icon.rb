class RemoveAreaIcon < ActiveRecord::Migration
  def self.up
    remove_column :areas, :icon_file_name
    remove_column :areas, :icon_content_type
    remove_column :areas, :icon_file_size
    remove_column :areas, :icon_updated_at
  end

  def self.down
    add_column :areas, :icon_updated_at, :datetime
    add_column :areas, :icon_file_size, :integer
    add_column :areas, :icon_content_type, :string
    add_column :areas, :icon_file_name, :string
  end
end
