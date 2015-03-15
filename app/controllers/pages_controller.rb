class PagesController < ApplicationController
  before_filter :get_criterio, :only => [:show]
  after_filter  :track_clickthrough, :only => [:show]

  # Not used
  # def index
  #   @title = t('pages.title')
  #   @pages = Page.published.paginate :page => params[:page],  :order => 'published_at DESC'
  #   respond_to do |format|
  #     format.html
  #     format.rss {render :layout => false}
  #   end
  # end

  def show
    begin
      @page = Page.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if is_admin?
        @page = Page.find(params[:id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end
    @title = @page.title
    
    # Not used. Consider adding download_tabs in aside
    #@videos_mpg = @page.videos[:mpg][I18n.locale.to_sym]
    
    if @category
      # Check whether category and page are related
      if @page.tags.all_private.collect(&:name_es) & @category.tags.all_private.collect(&:name_es) == []
        logger.info "Categoria y documento no relacionados"
        raise ActiveRecord::RecordNotFound
      end
    end

    # Flash pages must have '_flash' tag
    if @page.tag_list.include?('_flash')
      @flash_page = true
    end                 

    respond_to do |format|
      format.html { render }
      format.floki { render }
    end

  end

  private

  def make_breadcrumbs
    @breadcrumbs_info = []
    # @breadcrumbs_info << [t('pages.title'), pages_path]
    if @page && !@page.new_record?
      @breadcrumbs_info << [@page.title,  page_path(@page)]
    end
    @breadcrumbs_info
  end

end
