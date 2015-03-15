# Clase para mappear quién es el responsable de cada sala de streaming
class RoomManagement < ActiveRecord::Base
  belongs_to :room_manager
  belongs_to :stream_flow, :class_name => "StreamFlow", :foreign_key => "streaming_id"
end
