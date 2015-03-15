class CreateExternalFeeds < ActiveRecord::Migration
  def self.up
    create_table :external_feeds do |t|
      t.string :url, :null => false
      t.string :title
      t.string :provider
      t.string :encoding
      t.string :interval
      t.integer :organization_id
      t.datetime :last_import_at
      t.string   :last_import_status
      t.timestamps
    end
    
    ExternalFeed.create(:url => 'http://titulares.acceso.com/bin/ccode.cgi?clau=fbTv.ShxQYOsnORpJ6p9B.',
                        :title => 'Reseñas Lehendakaritza',
                        :provider => 'Acceso',
                        :interval => '1.hour',
                        :encoding => 'latin1', 
                        :organization_id => Organization.find_by_name_es('Presidencia'))
  end

  def self.down
    drop_table :external_feeds
  end
end
