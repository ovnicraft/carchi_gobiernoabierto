class DisableDocumentRatings < ActiveRecord::Migration
  def self.up
    Document.update_all("has_ratings='f'")
  end

  def self.down
  end
end
