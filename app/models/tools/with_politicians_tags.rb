# Métodos comunes para los contenidos que tienen asigando uno o varios políticos a través de los tags.
module Tools::WithPoliticiansTags
  
  def self.included(base)
    base.validate :politicians_names_are_valid    
  end

  def politicians_tags
    tags.all_public.politicians
  end
  
  def politicians_tag_list
    @politicians_tag_list || tags.all_public.politicians.map {|t| t.name}.join(", ")
  end
    
  def politicians_tag_list=(tag_names)
    # asignamos a la instance variable el valor que ha puesto el usuario para volver a mostrarlo si hay errores.
    @politicians_tag_list = tag_names 
    
    valid_names = true

    # Cogemos todos los tags menos los que corresponden a un político
    self.taggings = self.taggings.map {|t| t unless t.tag.kind.eql?('Político')}.compact
    
    logger.info "Assigns politicians tags for #{tag_names}"
    # Asignamos los tags nuevos
    tag_names.split(", ").each do |name_es|
      if t = ActsAsTaggableOn::Tag.politicians.find_by_name_es(name_es)
        self.tag_list << t.name
      else
        @politicians_errors = "No existe político con nombre #{name_es}"
        valid_names = false
      end
    end

    @politicians_tag_list
  end
  
  def public_tags_without_politicians
    self.tags.all_public.where("((kind IS NULL) OR (kind != 'Político'))")
  end
    
  def politicians_names_are_valid
    if @politicians_errors.present?
      errors.add(:politicians_tag_list, @politicinas_error)
    end
  end
  
  def politicians
    tags = self.politicians_tags
    politicians = []
    if tags.present?
      # Need to do separate finds if we want politicians to appear in the order they were introduced
      # Politician.where({"id" => tags.map {|t| t.kind_info}})
      tags.each do |tag|
        politicians << Politician.find(tag.kind_info)
      end
    end
    politicians
  end
 
  def politician_ids
    # tags = self.politicians_tags.map {|ptag| ptag.kind_info.to_i}
    tags = politicians.collect(&:id)
  end  
  
end