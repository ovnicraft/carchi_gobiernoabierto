class CreateBulletins < ActiveRecord::Migration
  def self.up
    create_table :bulletins, :force => true do |t|
      t.string   :title_es
      t.string   :title_eu
      t.string   :title_en
      t.datetime :sent_at
      t.text     :featured_news_ids, :null => false, :default => []
      t.timestamps
    end
    create_table :bulletin_copies do |t|
      t.integer :bulletin_id, :null => false
      t.integer :user_id
      t.datetime :sent_at
      t.datetime :opened_at
      t.text :news_ids, :null => false, :default => []
      t.timestamps
    end
    execute 'ALTER TABLE bulletin_copies ADD CONSTRAINT fk_bulletin_copies_bulletin_id_fk FOREIGN KEY (bulletin_id) REFERENCES bulletins(id)'
  end

  def self.down
    drop_table :bulletin_copies
    drop_table :bulletins
  end
end
