module Tools::Clickthroughable
  def self.included(base)
    base.has_many :clicks_from, -> { order("created_at DESC") }, :class_name => "Clickthrough", :foreign_key => "click_source_id", :as => :click_source, :dependent => :destroy
    base.has_many :clicks_to, -> { order("created_at DESC") }, :class_name => "Clickthrough", :foreign_key => "click_target_id", :as => :click_target, :dependent => :destroy
  end
  
end