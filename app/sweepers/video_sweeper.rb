class VideoSweeper <  ActionController::Caching::Sweeper 
  observe Video # This sweeper is going to keep an eye on the Video model  

  # If our sweeper detects that a Video was created or updated call this  
  def after_save(video)  
    expire_cache_for(video)  
  end  
  
  # If our sweeper detects that a Video was deleted call this  
  def after_destroy(video)  
    expire_cache_for(video)  
  end  

  def self.sweep
    Video::LANGUAGES.each do |lang|
      FileUtils.rm(ActionController::Base.page_cache_directory+"/#{lang}/podcast.xml") if File.exists?(ActionController::Base.page_cache_directory+"/#{lang}/podcast.xml")
    end
  end

  private 
  def expire_cache_for(record)  
    # Expire the podcast page now that we added a new video  
    # expire_page(:controller => '#{record}', :action => 'podcast')  
    Video::LANGUAGES.each do |lang|
      ActionController::Base.expire_page("/#{lang}/podcast.xml")  
    end
  end 
end 
