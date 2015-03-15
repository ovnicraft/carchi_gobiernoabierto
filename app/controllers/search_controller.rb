class SearchController < ApplicationController
  skip_before_filter :http_authentication, :only => :show # para las pruebas de Eli y Graficos
  before_filter :set_page, :only => [:show, :new, :create]
  before_filter :set_sort_order, :only => [:show, :create]

  def show
    @criterio=Criterio.find_by_id(params[:id])
    respond_to do |format|
      format.html {
        if @criterio.nil? || !do_elasticsearch_and_save_results(true, @criterio.only_title)
          redirect_to elasticsearch_not_available_redirect_url and return
        end  
      }
      format.json {
        all_results=Elasticsearch::Base::do_elasticsearch_with_facets(@criterio, 0, 'date', false, I18n.locale, 1000)
        @search_results = all_results.empty? ? [] : all_results['hits']
      }
    end
  end

  def new
    session[:criterio_id]=nil
    @sort = params[:sort].present? ? params[:sort] : 'date'
    @criterio = Criterio.new(:title => '')
    unless do_elasticsearch_and_save_results(false)
      redirect_to elasticsearch_not_available_redirect_url and return
    end
    respond_to do |format|
      format.html {render :action => 'show'}
    end
  end

  def create
    set_criterio
    redirect_to search_path(:id => @criterio.id, :sort => @sort)
  end

  def get_create
    set_criterio
    redirect_to search_path(:id => @criterio.id, :sort => @sort)
  end

  def set_criterio
    if params[:new]
      session[:criterio_id]=nil
    end
    if params[:value].blank?
      params[:value]='*'
    end
    title=String.new
    only_title = false
    if session[:criterio_id].present?
      parent_criterio = Criterio.find(session[:criterio_id])
      title << "#{parent_criterio.title} AND "
      only_title = parent_criterio.only_title
    end
    title << "#{params[:key]}: #{params[:value].strip}"
    @value = params[:value].strip
    @criterio = Criterio.create(:title => title, :parent_id => session[:criterio_id], :ip => request.remote_ip, :only_title => only_title)
  end

  def destroy
    @del_criterio=Criterio.find(params[:id])
    session[:criterio_id] = @del_criterio.parent_id.nil? ? nil : @del_criterio.parent_id
    unless @del_criterio.parent_id.nil?
      @criterio=Criterio.find(@del_criterio.parent_id)
    end
    # @del_criterio.destroy
    if session[:criterio_id].present?
      redirect_to search_path(:id => session[:criterio_id])
    else
      redirect_to new_search_path
    end
  end

  private
  def make_breadcrumbs
    if @criterio.present? && !@criterio.new_record?
      @breadcrumbs_info = [[t('search.title'), search_url(:id => @criterio.id)]]
    else
      @breadcrumbs_info = [[t('search.title'), new_search_url]]
    end
  end

end
