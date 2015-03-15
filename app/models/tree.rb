# Clase para los árboles de categorías, o dicho de otro modo, los diferentes
# menús de la web (Menú de Irekia, Canales de Web TV)
class Tree < ActiveRecord::Base
  translates :name
  has_many :categories, -> { order("position") }, :dependent => :destroy
  validates_uniqueness_of :name_es, :name_eu, :name_en, :label

  ['videos', 'albums'].each do |tree_label|
    self.class.instance_eval do
      define_method "find_#{tree_label}_tree" do 
        find_by_label(tree_label)
      end
    end
  end
end

