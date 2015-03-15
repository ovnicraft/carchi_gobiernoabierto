class EventSweeper < ActionController::Caching::Sweeper
  observe Event
  include Rails.application.routes.url_helpers

  # If our sweeper detects that a Event was created or updated call this
  def after_save(event)
    expire_cache_for(event)
  end
  
  # If our sweeper detects that a Event was deleted call this
  def after_destroy(event)
    expire_cache_for(event)
  end
          
  private
  def expire_cache_for(event)
    # fragment_cache_key doesn't work in test environment
    unless Rails.env.eql?('test')
      cache_base_path = Rails.application.config.action_controller.cache_store.last
      AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |locale|      
        # fragment_path = File.join(cache_base_path, fragment_cache_key(:controller => 'sadmin/events', :action => 'calendar', :action_suffix => "#{event.class.to_s.downcase}_#{event.id}"))
        key = {:controller => 'sadmin/events', :action => 'calendar', :action_suffix => "#{event.class.to_s.downcase}_#{event.id}", :locale => locale, :only_path => true}
        fragment_path = File.join(cache_base_path, ActiveSupport::Cache.expand_cache_key(url_for(key).split("://").last, :views).gsub("//", "/"))
        if Dir.exists?(fragment_path)
          Rails.logger.info "Expire fragment #{fragment_path}"
          FileUtils.rm_rf(fragment_path)
        end
      end
    end
  end
end
