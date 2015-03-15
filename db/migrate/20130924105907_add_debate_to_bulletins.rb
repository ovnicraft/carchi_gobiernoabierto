class AddDebateToBulletins < ActiveRecord::Migration
  def self.up
    add_column :bulletins, :featured_debate_ids, :text, :null => false, :default => []
    add_column :bulletin_copies, :debate_ids, :text, :null => false, :default => []
    add_column :debates, :featured_bulletin, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :bulletins, :featured_debate_ids
    remove_column :bulletin_copies, :debate_ids
    remove_column :debates, :featured_bulletin
  end
end
