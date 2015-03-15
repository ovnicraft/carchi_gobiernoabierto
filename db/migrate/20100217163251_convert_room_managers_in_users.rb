class ConvertRoomManagersInUsers < ActiveRecord::Migration
  class OldRoomManager < ActiveRecord::Base
    self.table_name = "room_managers"
    has_many :room_managements, :dependent => :destroy, :foreign_key => "room_manager_id"
  end
  def self.up
    OldRoomManager.all.each do |rm|
      passwd = Journalist.random_password
      user = RoomManager.new(:email => rm.email, 
        :password => passwd,
        :password_confirmation => passwd,
        :status => "aprobado",
        :name => rm.name.sub(/-.+$/, '').strip,
        :telephone => "#{rm.name.sub(/^.+-/, '').strip}: #{rm.telephone}",
        :has_event_alerts => true, 
        :alerts_locale => 'es')
      if user.save
        puts "Creado usuario para #{rm.name}\n"
        old_room_management_counter = rm.room_managements.count
        rm.room_managements.each do |rmm|
          puts "Cambiando el room_manager_id #{rm.id} al nuevo user.id #{user.id}"
          rmm.room_manager_id = user.id
          rmm.save!
        end
        if old_room_management_counter != user.room_managements.count
          puts "********* El numero de salas de las que era y es responsable no coincide: #{old_room_management_counter} != #{user.room_managements.count} *******"
        end
        
        old_event_alert_counter = EventAlert.count(:conditions => "spammable_id = #{rm.id} AND spammable_type = 'RoomManager'")
        EventAlert.where("spammable_id = #{rm.id} AND spammable_type = 'RoomManager'").each do |ea|
          puts "Cambiando el spammable_id #{rm.id} al nuevo user.id #{user.id} en las alertas ya enviadas"
          ea.spammable_id = user.id
          ea.save!
        end
        if old_event_alert_counter != EventAlert.count(:conditions => "spammable_id = #{user.id} AND spammable_type = 'RoomManager'")
          puts "********* El numero de alertas que tenia y tiene responsable no coincide: #{old_event_alert_counter} != #{EventAlert.count(:conditions => "spammable_id = #{user.id} AND spammable_type = 'RoomManager'")} *******"
        end
        
      else
        puts "No se ha creado el usuario para el responsable de sala #{rm.name}: #{user.errors.full_messages.join(', ')}\n"
        puts "Borramos los room managements que tenia este responsable, ya que ya no va a existir"
        rm.room_managements.each do |rmm|
          rmm.destroy
        end
        puts "Borramos las alertas que le habiamos enviado"
        EventAlert.delete_all("spammable_id = #{rm.id} AND spammable_type = 'RoomManager'")
      end
      puts "==========="
    end
    
    drop_table :room_managers
  end

  def self.down
    create_table "room_managers", :force => true do |t|
      t.string   "name",       :null => false
      t.string   "email",      :null => false
      t.string   "telephone"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    RoomManager.all.each do |rm|
      rm.destroy
    end
  end
end
