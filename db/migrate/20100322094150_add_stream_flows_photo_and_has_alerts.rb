class AddStreamFlowsPhotoAndHasAlerts < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :photo_file_name, :string
    add_column :stream_flows, :photo_content_type, :string
    add_column :stream_flows, :photo_file_size, :integer
    add_column :stream_flows, :photo_updated_at, :timestamp
    add_column :stream_flows, :send_alerts, :boolean, :default => true
    
    execute "UPDATE stream_flows SET send_alerts='t'"
    
    rename_column :stream_flows, :photo, :photoxx
    StreamFlow.all.each do |sf|
      if sf.photoxx
        sf.photo = File.new("#{Rails.root}/public/images/streaming_rooms/#{sf.photoxx}")
        sf.save!
      end
    end
    
    remove_column :stream_flows, :photoxx
  end

  def self.down
    remove_column :stream_flows, :send_alerts
    remove_column :stream_flows, :photo_updated_at
    remove_column :stream_flows, :photo_file_size
    remove_column :stream_flows, :photo_content_type
    remove_column :stream_flows, :photo_file_name
  end
end
