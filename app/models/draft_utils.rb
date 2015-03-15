module DraftUtils
  module InstanceMethods
    # Garantiza que las noticias en borrador no tienen fecha de publicación.
    # Se llama desde before_save
    def sync_draft_and_published_at
      if self.draft == "1"
        self.published_at = nil
      else
        self.published_at = Time.zone.now if self.published_at.nil?
      end
    end
    
    def draft=(val)
      @draft = val
    end
    
    def draft
      if @draft.nil?
        self.published_at.nil? ? "1" : "0"
      else
        @draft
      end
    end
  end
  
  module ClassMethods
    
  end
end