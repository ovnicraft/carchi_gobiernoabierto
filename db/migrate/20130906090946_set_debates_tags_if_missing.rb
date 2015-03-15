#
# En el traspaso de las propuestas a debates algunos debates se han quedado sin tag.
# Este migration crea los tags que faltan.
#

class SetDebatesTagsIfMissing < ActiveRecord::Migration
  def self.up
    Debate.all.each do |debate|
      if debate.debate_tag.nil?
        p "Creando el tag del debate #{debate.id}"
        new_tag_name = debate.hashtag
        tag = Tag.new(:name_es => new_tag_name, :name_eu => new_tag_name, :name_en => new_tag_name)
        tag.taggings.build(:taggable => debate)
        tag.save!
      else
        p "Debate #{debate.id} OK"
      end
    end
  end

  def self.down
  end
end
