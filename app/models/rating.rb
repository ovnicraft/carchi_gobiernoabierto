# Clase para las valoraciones de los comentarios, y antiguamente de las noticias
class Rating < ActiveRecord::Base
  belongs_to :rateable, :polymorphic => :true
  validates_numericality_of :rating, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 5, :if => Proc.new {|rating| rating.rateable_type.eql?('Document')}
  validates_numericality_of :rating, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1, :if => Proc.new {|rating| rating.rateable_type.eql?('Comment')}
end
