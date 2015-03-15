class RemovePhotoAndDraftFromContributions < ActiveRecord::Migration
  def self.up
    remove_column :contributions, :photo_file_name
    remove_column :contributions, :photo_content_type
    remove_column :contributions, :photo_file_size
    remove_column :contributions, :photo_updated_at
    Contribution.where("draft='t' and published_at is not null").each do |contribution|
      contribution.destroy
    end
    remove_column :contributions, :draft
  end

  def self.down
    add_column :contributions, :draft, :boolean,                              :default => false, :null => false
    add_column :contributions, :photo_updated_at, :datetime
    add_column :contributions, :photo_file_size, :integer
    add_column :contributions, :photo_content_type, :string
    add_column :contributions, :photo_file_name, :string
  end
end
