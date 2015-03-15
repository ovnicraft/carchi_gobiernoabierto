class CreateAdminStreamFlows < ActiveRecord::Migration
  def self.up
    create_table :stream_flows do |t|
      t.string :title_es, :null => false
      t.string :title_eu
      t.string :title_en
      t.string :code, :null => false
      t.boolean :show_in_agencia, :default => false
      t.timestamps
    end
    
    StreamFlow.create(:title_es => "Lehendakaritza", :code => "myStream3.sdp")
    StreamFlow.create(:title_es => "Cámara Móvil Lehendakari", :code => "myStream4.sdp")
  end

  def self.down
    drop_table :stream_flows
  end
end
