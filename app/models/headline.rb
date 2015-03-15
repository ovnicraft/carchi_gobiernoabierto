class Headline < ActiveRecord::Base
  validates_presence_of :title, :media_name, :source_item_id, :source_item_type, :url, :published_at
  validates_uniqueness_of :source_item_id, :scope => :source_item_type
  
  acts_as_ordered_taggable
  include Tools::WithAreaTag       
  # include Tools::WithActions
  
  scope :published, -> { where(:draft => false).reorder('published_at DESC, score DESC') }
  scope :translated, -> { where(:locale => I18n.locale.to_s.eql?('en') ? 'es' : I18n.locale.to_s) } 
  scope :recent, -> { where(["published_at > ?", 3.days.ago])} 
  
  before_create :set_draft
  
  # All headlines must be previously moderated
  def set_draft
    self.draft = true
  end

end  