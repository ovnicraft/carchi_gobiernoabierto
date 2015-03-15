class Snetwork <ActiveRecord::Base
  belongs_to :sorganization
  
  before_save :set_social_network_label
  
  attr_accessor :deleted
  
  validates_presence_of :url
  validates_format_of   :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  validates_uniqueness_of :url
  
  TYPES = ['twitter', 'facebook', 'tuenti', 'youtube', 'flickr', 'slideshare', 'delicious', 'blogger', 'linkedin', 
            'vimeo', 'wordpress', 'picasa', 'tumblr', 'scribd', 'wiki', 'prezi', 'foursquare', 'gowalla', 
            'openideiak', 'ning', 'blip', 'qik', 'xing', 'posterous', 'picotea', 'blog', 'google', 'issuu', 'pinterest', 'ivoox', 'diigo']  
    
  def <=>(other_snetwork)
    res=Snetwork::TYPES.index(self.label).to_i <=> Snetwork::TYPES.index(other_snetwork.label).to_i 
    if res==0 
      res= (self.position <=> other_snetwork.position)
    end
    res  
  end

  def set_social_network_label
    if self.url 
      TYPES.each do |type|
        if self.url.gsub('.', '').include?(type)
          self.label=type 
          break
        end  
      end
      self.label='other' if self.label.nil?
    end  
  end  

  def pretty_url
    self.url.gsub(/https?\:\/\//, '')[0..25] if self.url
  end
  
end  
