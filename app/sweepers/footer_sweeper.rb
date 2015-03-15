class FooterSweeper < ActionController::Caching::Sweeper
  observe Banner, Area # This sweeper is going to keep an eye on the Banner and Area models

  # If our sweeper detects that a Banner or Area was created or updated call this
  def after_save(item)
    expire_cache_for(item)
  end
  
  # If our sweeper detects that a Banner or Area was deleted call this
  def after_destroy(item)
    expire_cache_for(item)
  end
          
  private
  def expire_cache_for(record)
    # Expire a fragment
    AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |locale|
      # NOTE: if you change cache location, change irekia4_init.rake#import_banners accordingly
      # ActionController::Base.new.
      ActionController::Base.new.expire_fragment("footer_#{locale.to_s}") 
    end
  end
end
