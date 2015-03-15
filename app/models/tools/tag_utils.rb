#
# Funciones auxiliares para revisar la consistencia de los tags y unificar tags duplicados.
# La función de juntar tags duplicados, merge_duplicated_tags!, se usa en admin/tags_controller.
# Las demás funciones se usan desde la consola.
#
# eli@efaber.net, 26-06-2012
module Tools::TagUtils
  # eli@efaber.net (21-06-2012)
  # Si hay un tag de político en la lista, usamos este como referencia
  # Si no hay políticos, cogemos como referencia el tag que más contenidos tiene. 
  def merge_duplicated_tags!
    tags2merge = ActsAsTaggableOn::Tag.duplicated_tags
    
    tags2merge.group_by(&:sanitized_name_es).each do |san_name, tags|
      tags.sort!{|c1, c2| c2.taggings.count <=> c1.taggings.count}
      reference_tag = tags.detect {|t| t.kind.eql?('Político')} || tags.first
      dup_tags = tags - [reference_tag]
      merge_tags(reference_tag, dup_tags)
    end
  end
  
  def merge_duplicated_politician_tags!
    ActsAsTaggableOn::Tag.find_by_sql("SELECT distinct on (t1.id) t1.id, t1.name_es, t1.sanitized_name_es, t1.name_eu, t1.sanitized_name_eu, t1.kind, t1.kind_info 
             FROM tags t1, tags t2
             WHERE t1.kind='Político' AND t1.id<>t2.id AND t1.kind_info = t2.kind_info 
              AND t1.kind = t2.kind").group_by(&:kind_info).each do |kind_info, tags|
      p "Tags del político #{kind_info}: #{tags.map {|t| "#{t.name} (#{t.id})"}.join(", ")}"         
      reference_tag = tags.first
      dup_tags = tags - [reference_tag]
      merge_tags(reference_tag, dup_tags)      
    end
  end
  
  def check_politicians_tags_names
    Politician.all.each do |politician|
      if politician.tag.present?
        if politician.public_name != politician.tag.name
          p "ERROR: político #{politician.public_name} - tag #{politician.tag.name}"
        else
          p "OK: #{politician.public_name}"
        end
      else
        p "ERROR: no hay tag para el político #{politician.public_name} (#{politician.id})"
      end
    end
  end
  
  def check_for_politicians_and_persons_with_same_gc_id
    ActsAsTaggableOn::Tag.where(:kind => 'Persona').each do |tag|
      if tag.kind_info.present?
        if politician = Politician.find_by_gc_id(tag.kind_info.to_i)
          p "REVISAR: tag #{tag.name} (#{tag.id}), político #{politician.public_name} (#{politician.id})"
        end
      end
    end
  end
  
  def check_for_politicians_without_tags
    Politician.all.each do |ptn|
      if !ptn.tag.present?
        p "REVISAR: político sin tag #{ptn.public_name} (#{ptn.id})"
      end
    end
  end
  
  private
  
  def merge_tags(reference_tag, tags2remove)
    tags2remove.each do |tag|
      p "Taggings: #{tag.taggings.map {|tagging| "#{tagging.taggable_type}: #{tagging.taggable_id}"}.join(", ")}"
      ActsAsTaggableOn::Tagging.where("tag_id=#{tag.id}").update_all("tag_id=#{reference_tag.id}")
      ActsAsTaggableOn::Tag.find(tag.id).destroy
    end    
  end
  
end
