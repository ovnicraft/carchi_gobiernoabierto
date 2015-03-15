# Controlador para los tags
class TagsController < ApplicationController
  skip_before_filter :http_authentication, :only => :show # para las pruebas de Eli y Graficos  
  before_filter :set_page, :only => [:show]
  # before_filter :set_sort_order, :only => [:show]
  
  # Listado de tags
  def index
    @title = t('tags.title')
    conditions = "published_at <= '#{Time.zone.now.strftime('%Y-%m-%d %H:%M')}' "
    
    @ttype = params[:type]
    
    all_tags = Document.published.where(conditions).tag_counts
    @tags = all_tags.to_a.sort! {|a, b| b.count <=> a.count}[0..100].sort! {|a, b| a.sanitized_name <=> b.sanitized_name}
  end                         

  # Contenidos taggeados con un tag
  def show
    if params[:id].match(/^_/)
      tags = ActsAsTaggableOn::Tag.where(sanitized_name_es: params[:id])
    elsif params[:id].match(/^\d+$/)
      tags = [ActsAsTaggableOn::Tag.find(params[:id])]
    else
      tags = ActsAsTaggableOn::Tag.find_by_sql(["SELECT * FROM tags WHERE (sanitized_name_es=? OR sanitized_name_eu=? OR sanitized_name_en=?)", params[:id], params[:id], params[:id]])
    end
    if tags.empty?
      render :template => '/site/notfound.html', :status => 404 and return
    else                           
      session[:criterio_id] = nil       
      @tag = tags.first          
      @sort = 'date'
      # TODO: temp fix
      if @tag.criterio_id.present?
        #if @tag.updated_at > @criterio.updated_at
        #  @tag.criterio.update_attribute(:title, @tag.criterio_title)
        #end
        @criterio = Criterio.find_by_id(@tag.criterio_id)
      else
        @criterio = Criterio.create(:title => @tag.criterio_title, :ip => request.remote_ip)
        # @tag.create_criterio(:title => @tag.criterio_title, :ip => request.remote_ip)
        @tag.update_attribute(:criterio_id, @criterio.id)
      end
      
      unless @tag.criterio_id.present? && !@criterio.nil?                                              
        title = @tag.criterio_title
        title << " AND type: #{params[:type].downcase}" if params[:type].present? && !params[:type].eql?('all')
        @criterio = Criterio.create(:title => title, :parent_id => nil, :ip => request.remote_ip)
        redirect_to search_url(:id => @criterio.id) and return
      end
      if params[:type].present? && !params[:type].eql?('all')
        @criterio.title << " AND type: #{params[:type].downcase}"
      end
      respond_to do |format|
        format.html {
          unless do_elasticsearch_and_save_results(true, false)
            redirect_to elasticsearch_not_available_redirect_url and return
          end  
          render :template => '/search/show' and return             
        }
        format.json {
          all_results=Elasticsearch::Base::do_elasticsearch_with_facets(@criterio, 0, 'date', false, I18n.locale, 1000)
          @search_results = all_results.empty? ? [] : all_results['hits']
          render :template => '/search/show' and return             
        }
      end
    end
  end              
  
  # POST
  def search
    tag = ActsAsTaggableOn::Tag.send("find_all_by_sanitized_name_#{I18n.locale.to_s}", params[:id]).first    
    if tag.nil? || tag.name.match(/^_/) 
      render :template => '/site/notfound.html', :status => 404 and return
    end
    session[:criterio_id] = nil
    title = "tags: #{tag.name_es}|#{tag.name_eu}|#{tag.name_en}"
    @criterio = Criterio.create(:title => title, :parent_id => nil, :ip => request.remote_ip)
    redirect_to search_url(:id => @criterio.id) and return
  end
  
  private
  # Construye los breadcrumbs de cada acción de los tags
  def make_breadcrumbs
    @breadcrumbs_info = [[t('tags.title'), tags_path]]    
    if @tag && !@tag.new_record?
      @breadcrumbs_info = [[@tag.name, tag_path(@tag)]]
    end
    @breadcrumbs_info
  end

end
