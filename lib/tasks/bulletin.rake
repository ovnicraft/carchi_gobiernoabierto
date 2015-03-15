# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')
require File.join(Rails.root, 'lib', 'tasks', 'rake_utils')

namespace 'bulletin' do

  desc "Send bulletin"
  task :send_bulletin do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      # process_logger = Logger.new(STDOUT)
      process_logger.info("#{Time.zone.now.to_s(:short)}: Checking for bulletins to be sent...")

      bulletin = Bulletin.pending.first

      if bulletin
        Bulletin.subscribers.order("id").each do |user|
          sleep 2
          process_logger.info "to #{user.bulletin_email}"
          copy = user.bulletin_copies.build(:bulletin_id => bulletin.id)

          if copy.save && copy.sent?
            process_logger.info "El boletín #{copy.id} para #{user.bulletin_email} SÍ se ha enviado"
          else
            process_logger.info "El boletín #{copy.id} para #{user.bulletin_email} NO se ha enviado: #{copy.errors.full_messages.join('. ')}"
          end
        end
        bulletin.update_attributes(:sent_at => Time.zone.now)
      else
        process_logger.info "No bulletin to be sent"
      end
    end
  end

  desc "Send email to all Irekia users announcing the new Bulletin service"
  task :announce_bulletin_service do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      # process_logger = Logger.new(STDOUT)
      
      process_logger.info("#{Time.zone.now.to_s(:short)}: Announcing bulletin...")
      # all_users = User.approved.find :all, :conditions => "id in (1)", :order => "id"
      all_users = User.approved.with_email.find :all, :conditions => "coalesce(email, '')<>'' AND wants_bulletin='f'", :order => "id"
      
      all_users.each do |user|
        notification = BulletinMailer.announce(user)
        begin
          notification.deliver
        rescue Timeout::Error => err
          process_logger.info "skipping because of #{err}"
        rescue => err_type
          process_logger.info("\tThere were some errors sending event alert: " + err_type)
        else
          process_logger.info "Sent to #{user.id}: #{user.bulletin_email}"
        end
        sleep 2
      end
      process_logger.info "#{Time.zone.now.to_s(:short)}: Finished."
    end
  end
  
  desc "Deletes all bulletins and copies and resets the sequences"
  task :reset_bulletins do
    Bulletin.all.each do |bulletin|
      puts bulletin.inspect
      bulletin.destroy
    end
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE bulletins_id_seq RESTART")
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE bulletin_copies_id_seq RESTART")
  end
end
