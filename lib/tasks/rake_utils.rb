# encoding: UTF-8
class RakeUtils
  def self.with_lock_file(task_name)
    filename = self.task_filename(task_name)
    base_dir = File.join(Rails.root, 'log/')
    lock_file = File.join(base_dir, "#{filename}.lock")
    log_file = File.join(base_dir, "#{filename}.log")
    puts "Logging in #{log_file} and locking in #{lock_file}"
    process_logger = Logger.new(log_file)
    if File.exists?(lock_file)
      process_logger.info("#{Time.zone.now.to_s(:short)}: #{filename} is locked by another process. Aborting...")
      if File.ctime(lock_file) < 3.hours.ago
        raise RakeUtilsException,  "The lock file #{lock_file} seems to be very old.\nPlease check \"#{task_name}\" rake task is working properly.\n"
      end
    else
      File.open(lock_file, 'w') do |f|
        f.write(Time.zone.now)
      end
      yield process_logger
      File.delete(lock_file)
    end
  end
  
  def self.task_filename(task_name)
    task_filename = task_name.to_s.split(':').last
  end
end

class RakeUtilsException < StandardError
end
