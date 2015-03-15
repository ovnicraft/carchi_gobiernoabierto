class AddAnnouncedForStreamFlows < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :announced_in_irekia, :boolean, :default => false
    add_column :stream_flows, :announced_in_agencia, :boolean, :default => true
    add_column :stream_flows, :photo, :string
    
    [["SBI03.SDP", "BI-pzabizkaia.jpg"], 
     ["SBI02.SDP", "BI-pzabizkaia.jpg"], 
     ["SGI01.SDP", "SS-andia13.jpg"], 
     ["SBI01.SDP", "BI-pzabizkaia.jpg"], 
     ["SIT01.SDP", "Lehend-declaraciones.jpg"], 
     ["SAR02.SDP", "VI-salaprensa-lakuaII.jpg"],
     ["SAR01.SDP", "Lehend-prensa-portavoz.jpg"]].each do |pair|
      if sf = StreamFlow.find_by_code(pair.first)
        sf.update_attribute(:photo, pair.last)
      end
    end
  end

  def self.down
#    remove_column :atream_flows, :photo
    remove_column :stream_flows, :announced_in_agencia
    remove_column :stream_flows, :announced_in_irekia
  end
end
