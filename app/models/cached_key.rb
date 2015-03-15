# Clase para los keywords cacheados
class CachedKey < ActiveRecord::Base
  belongs_to :cacheable, :polymorphic => true
end  