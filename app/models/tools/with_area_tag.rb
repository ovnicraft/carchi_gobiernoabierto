# Métodos comunes para los contenidos que tienen asignado un área a través del tag del área .
module Tools::WithAreaTag

  attr_accessor :old_area
  attr_accessor :tag_list_without_areas

  def self.included(base)
    base.before_save :save_tag_list_and_area_tag_list
    base.before_save :set_area_will_change
    base.after_save :sync_comments_area_tags
    # Set old_area when changing tags via tag_list.add, tag_list.remove or tag_list=
    base.alias_method_chain :set_tag_list_on, :old_area
    base.alias_method_chain :tag_list_on, :old_area
  end

  # El área de un documento se coge de los tags de áreas que este tiene.
  # Se ordenan de acuerdo con el orden oficial de las áreas
  def areas
    # I tried to memoize value like this but many tests broke
    # @area ||= Area.joins(:taggings).where("taggings.tag_id" => self.tag_ids).order(:position)
    Area.joins(:taggings).where("taggings.tag_id" => self.tag_ids).order(:position)
  end

  # Si hay más de un área que corresponde al documento, usamos el órden de las áreas
  # y cogemos el primero.
  def area
     self.areas.first
  end

  def area_id
    area.id if area
  end

  def area_tag
    if @area_tags.present? && @area_tags.delete_if {|at| at.eql?("")}.length > 0
      Area.tagged_with(@area_tags, :any => true).order('position').first.area_tag
    elsif self.area.present?
      area.area_tag
    end
  end

  def area_changed?
    changed.include?('area')
  end

  def area_name
    self.area.present? ? self.area.name : ''
  end

  def area_tags
    @area_tags ||= ActsAsTaggableOn::TagList.from(tag_list.select {|t| t.match(/^_a_/)})
  end

  def area_tags=(area_tag_array)
    self.old_area = self.area
    @area_tags = area_tag_array
    self.tag_list = self.tag_list.reject {|t| t.match(/^_a_/)} + area_tag_array
  end

  def area_ids
    areas.collect(&:id)
  end

  def tag_list_without_areas
    # @tag_list_without_areas ||= tag_list.reject {|t| t.match(/^_a_/)}
    @tag_list_without_areas ||= ActsAsTaggableOn::TagList.from(tag_list.reject {|t| t.match(/^_a_/)})
  end

  def tag_list_without_areas=(tag_list_without_areas_string)
    @tag_list_without_areas = ActsAsTaggableOn::TagList.from(tag_list_without_areas_string)
    self.tag_list = self.tag_list.select {|t| t.match(/^_a_/)} + @tag_list_without_areas
  end

  def set_tag_list_on_with_old_area(context, new_list)
    self.old_area = self.area
    set_tag_list_on_without_old_area(context, new_list)
  end

  def tag_list_on_with_old_area(context, locale=I18n.locale)
    self.old_area = self.area
    tag_list_on_without_old_area(context, locale=I18n.locale)
  end

  protected
  def sync_comments_area_tags
    # logger.info "respond_to? :comments: #{self.respond_to?(:comments)}"
    if self.respond_to?(:comments)
      # logger.info "Added: #{self.added_tags.inspect}. Removed: #{self.removed_tags.inspect}"
      # En el ORM hay un objeto nil al hacer Area.tags
      # en la DB no se encuentra ese objeto
      every_area_tag_names = Area.tags.collect {|a| a.name_es if a != nil}
      to_add = (self.added_tags & every_area_tag_names)
      to_remove = (self.removed_tags & every_area_tag_names)
      if to_add.length > 0 || to_remove.length > 0
        self.comments.each do |comment|
          if to_add.length > 0
            logger.info "Going to add tag areas #{to_add.join(',')} to comment #{comment.id}"
            comment.tag_list.add to_add
          end
          if to_remove.length > 0
            logger.info "Going to remove tag areas #{to_remove.join(',')} from comment #{comment.id}"
            comment.tag_list.remove to_remove
          end
          comment.save!
        end
      end
    end
  end

  def save_tag_list_and_area_tag_list
    if @area_tags || @tag_list_without_areas
      new_tag_list = []
      new_tag_list += area_tags
      new_tag_list += tag_list_without_areas
      self.tag_list = ActsAsTaggableOn::TagList.from(new_tag_list).uniq
      # self.tag_list.add tags
    end
  end

  def cache_old_area
    self.old_area = self.area
  end

  def set_area_will_change
    # Warning: it is not allowed to tag content via taggings.build (?)
    new_area_tags = self.tag_list.select {|t| t.match(/^_a_/)}
    new_area = Area.tagged_with(new_area_tags, :any => true).order('position').first

    attribute_will_change!('area') if old_area != new_area
    return true
  end
end
