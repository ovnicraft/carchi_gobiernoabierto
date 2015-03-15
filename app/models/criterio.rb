class Criterio < ActiveRecord::Base
  validates_presence_of :title, :ip
  has_one :tag

  include Tools::Clickthroughable
  
  acts_as_tree

  SORT_ORDER = ['score', 'date']
  
  def get_keywords
    keyword = []
    self.title.split(' AND ').each do |part|   
      matching = part.match(/keyword: (.*)/)
      keyword << matching[1] if matching.present? && matching[1] != '*'
    end               
    keyword = keyword.join(' ')                                            
    keyword.gsub!(/\b([A-z]{1,2}|con|del|las|los|para|por|que|una)\s/, '') if keyword.present?
    return keyword    
  end

  def last_part
    self.title.split(' AND ').last.to_s
  end
  
end  
