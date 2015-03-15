#
# Cambiar el nombre de los tags de debate de _d_* al hashtag del debate.
#
class ChangeDebateTags < ActiveRecord::Migration
  def self.up
    Tag.where("name_es ilike '\\_d\\_%'").map {|t| t if t.name_es.match(/^_d_/)}.compact.each do |tag|
      hashtag = tag.name_es.gsub(/^_d_/, '#')
      if d = Debate.find_by_hashtag(hashtag)
        p "Changing tag #{tag.id}: name_es = #{tag.name_es}, debate = #{d.title}, hashtag = #{hashtag}"
        tag.name_es = hashtag
        tag.name_eu = hashtag        
        tag.name_en = hashtag                
        tag.save
      end
    end
  end

  def self.down
  end
end
