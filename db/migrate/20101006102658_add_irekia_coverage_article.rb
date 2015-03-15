class AddIrekiaCoverageArticle < ActiveRecord::Migration
  def self.up
    add_column :documents, :irekia_coverage_article, :boolean, :default => false
  end

  def self.down
    remove_column :documents, :irekia_coverage_article
  end
end
