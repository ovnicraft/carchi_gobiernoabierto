class AddVideosSubtitles < ActiveRecord::Migration
  def self.up
    add_column :videos, :subtitles_es_file_name, :string
    add_column :videos, :subtitles_es_content_type, :string
    add_column :videos, :subtitles_es_file_size, :integer
    add_column :videos, :subtitles_es_updated_at, :datetime
    add_column :videos, :subtitles_es_updated_by, :integer

    add_column :videos, :subtitles_eu_file_name, :string
    add_column :videos, :subtitles_eu_content_type, :string
    add_column :videos, :subtitles_eu_file_size, :integer
    add_column :videos, :subtitles_eu_updated_at, :datetime
    add_column :videos, :subtitles_eu_updated_by, :integer

    add_column :videos, :subtitles_en_file_name, :string
    add_column :videos, :subtitles_en_content_type, :string
    add_column :videos, :subtitles_en_file_size, :integer
    add_column :videos, :subtitles_en_updated_at, :datetime
    add_column :videos, :subtitles_en_updated_by, :integer

  end

  def self.down
    remove_column :videos, :subtitles_es_updated_by
    remove_column :videos, :subtitles_es_updated_at
    remove_column :videos, :subtitles_es_file_size
    remove_column :videos, :subtitles_es_content_type
    remove_column :videos, :subtitles_es_file_name
    
    remove_column :videos, :subtitles_eu_updated_by
    remove_column :videos, :subtitles_eu_updated_at
    remove_column :videos, :subtitles_eu_file_size
    remove_column :videos, :subtitles_eu_content_type
    remove_column :videos, :subtitles_eu_file_name

    remove_column :videos, :subtitles_en_updated_by
    remove_column :videos, :subtitles_en_updated_at
    remove_column :videos, :subtitles_en_file_size
    remove_column :videos, :subtitles_en_content_type
    remove_column :videos, :subtitles_en_file_name
  end
end