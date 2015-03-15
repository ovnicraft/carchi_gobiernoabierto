# Controlador para la traducción de Tags
class Admin::TagsController < Admin::BaseController
  include Tools::TagUtils
  
  in_place_edit_for :tag, :name_es
  in_place_edit_for :tag, :name_eu
  in_place_edit_for :tag, :name_en
  in_place_edit_for :tag, :kind
  in_place_edit_for :tag, :kind_info  
  
  # Listado de tags
  def index
    if params[:q]
      conditions = ["sanitized_name_es || ' ' || sanitized_name_eu || ' ' || sanitized_name_en LIKE ?", "%#{params[:q].tildes.downcase}%"]
      @title = "Tags: #{params[:q]}"
    elsif params[:l]
      @l = params[:l]
      if (@l=='A')
        conditions = ["sanitized_name_es LIKE ? and sanitized_name_es NOT LIKE ?", "#{@l.downcase}%","#{'acuerdosdelconsejodegobiernode'}%"]
      elsif @l.eql?('hashtag')
        conditions = "name_es LIKE '#%'"
      else 
        conditions = ["sanitized_name_es LIKE ?", "#{@l.downcase}%"]
      end
      @title = "Tags: #{@l}"
    else
      conditions = nil
    end
    
    if conditions
      @tags = ActsAsTaggableOn::Tag.all_public.where(conditions).order("tildes(lower(name_es))")
    else
      @tags = ActsAsTaggableOn::Tag.count < 100 ? ActsAsTaggableOn::Tag.all_public.order("tildes(lower(name_es))"): []
    end
  end
  
  # Busca los tags duplicados
  def find_duplicates
    @duplicated_tags = ActsAsTaggableOn::Tag.duplicated_tags
  end
  
  # Busca los tags duplicados y los reagrupa en un sólo tag
  def merge
    if params[:cancel]
      flash[:notice] = "Los tags se han dejado como estaban"
      
    else
      merge_duplicated_tags!
      # @duplicated_tags = Tag.duplicated_tags
      # 
      # @duplicated_tags.group_by(&:sanitized_name_es).each do |san_name, tags|
      #   tags.sort!{|c1, c2| c2.taggings.count <=> c1.taggings.count}
      #   reference_tag = tags.first
      #   duplicated_tags = tags - [tags.first]
      #   duplicated_tags.each do |tag|
      #     ActsAsTaggableOn::Tagging.update_all("tag_id=#{reference_tag.id}", "tag_id=#{tag.id}")
      #     ActsAsTaggableOn::Tag.find(tag.id).destroy
      #   end
      # end
      flash[:notice] = "Los tags se han agrupado"
    end
    redirect_to admin_tags_path
  end
  
  def update
    update_tag(tag_params)
  end

  def set_tag_kind
    update_tag({:kind => params[:value]})
  end

  def set_tag_kind_info
    update_tag({:kind_info => params[:value]})
  end
  
  def set_tag_name
    update_tag({"name_#{params[:locale]}" => params[:value]})
  end

  def update_tag(tag_attributes)
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    if @tag.update_attributes(tag_attributes)
      render :action => :update
    else
      render :action => :update, :status => 422
    end
  end

  private
  def set_current_tab
    @current_tab = :tags
  end

  def tag_params
    params.require(:tag).permit(:translated)
  end
  
end
